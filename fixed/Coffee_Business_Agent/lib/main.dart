import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String agentName = 'Coffee Business Agent';
const String agentSubtitle = 'مدير مشروع القهوة الذكي';
const String systemPrompt = r'''أنت Coffee Business Agent، مستشار ومدير تشغيل متخصص في مشاريع القهوة والكافيهات. تواصل بالعربية المصرية الواضحة ما لم يطلب المستخدم غير ذلك.
اختصاصاتك: دراسة السوق والمنافسين، بناء المنيو، توحيد وصفات المشروبات، حساب تكلفة الوصفات والخامات والعبوات والهالك، التسعير وهامش الربح، المشتريات والمخزون ونقاط إعادة الطلب، الموردون، العمالة والتشغيل، خدمة العملاء، التسويق والعروض، تحليل المبيعات، التدفقات النقدية، الأرباح والخسائر وخطط التوسع.
قواعد العمل:
- لا تخترع أسعار خامات أو مبيعات أو أرقام سوقية. اطلب البيانات الناقصة أو وضح الافتراضات.
- عند حساب منتج اعرض المعادلة والوحدات والتكلفة وسعر البيع والربح الإجمالي والهامش، وميّز بين هامش الربح والزيادة على التكلفة.
- اسأل سؤالاً واحداً فقط إذا كانت معلومة أساسية تمنع العمل؛ وإلا ابدأ بافتراضات معلنة.
- قدم توصيات قابلة للتنفيذ مرتبة بالأولوية مع أثر متوقع ومؤشر قياس.
- عند تحليل ملفات المبيعات اذكر الفترة والعملة ونواقص البيانات.
- لا تدّع تنفيذ شراء أو تعديل مخزون أو إرسال إعلان دون أداة فعلية.
- وضح أن الأسعار السوقية تحتاج بيانات حديثة من السوق المحلي.''';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgentApp());
}

class ChatMessage {
  final String role;
  final String content;
  ChatMessage(this.role, this.content);
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(json['role'] as String, json['content'] as String);
}

class AgentApp extends StatelessWidget {
  const AgentApp({super.key});
  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF176B63);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: agentName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _secure = FlutterSecureStorage();
  static const _historyKey = 'coffee_agent_chat_history_v1';
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _model = 'gpt-4.1';
  String _apiKey = '';
  bool _busy = false;
  String? _attachedText;
  String? _attachedName;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_historyKey);
    final key = await _secure.read(key: 'coffee_agent_openai_key');
    if (!mounted) return;
    setState(() {
      _apiKey = key ?? '';
      if (saved != null) {
        try {
          final list = jsonDecode(saved) as List<dynamic>;
          _messages.addAll(list.map((e) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))));
        } catch (_) {}
      }
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey,
        jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }

  Future<void> _settings() async {
    final keyController = TextEditingController(text: _apiKey);
    final modelController = TextEditingController(text: _model);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعدادات المساعد'),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'مفتاح OpenAI API',
                hintText: 'sk-...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'اسم الموديل'),
            ),
            const SizedBox(height: 8),
            const Text(
              'يُحفظ المفتاح في التخزين الآمن على هذا الجهاز. لا تشاركه مع أحد.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final newKey = keyController.text.trim();
              if (newKey.isEmpty) {
                await _secure.delete(key: 'coffee_agent_openai_key');
              } else {
                await _secure.write(key: 'coffee_agent_openai_key', value: newKey);
              }
              if (!mounted) return;
              setState(() {
                _apiKey = newKey;
                _model = modelController.text.trim().isEmpty
                    ? 'gpt-4.1'
                    : modelController.text.trim();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    keyController.dispose();
    modelController.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'csv', 'json', 'log'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.size > 2 * 1024 * 1024) {
      _notice('الحد الأقصى للملف النصي 2 ميجابايت.');
      return;
    }
    final bytes = file.bytes;
    if (bytes == null) {
      _notice('تعذر قراءة الملف على هذا الجهاز.');
      return;
    }
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.length > 60000) {
      text = text.substring(0, 60000);
      _notice('الملف كبير؛ سيتم إرسال أول 60,000 حرف فقط.');
    }
    setState(() {
      _attachedText = text;
      _attachedName = file.name;
    });
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    if (_apiKey.isEmpty) {
      await _settings();
      if (_apiKey.isEmpty) {
        _notice('أضف مفتاح API من الإعدادات أولاً.');
        return;
      }
    }

    final userContent = _attachedText == null
        ? text
        : '$text\n\nمحتوى الملف المرفق ($_attachedName):\n$_attachedText';
    setState(() {
      _messages.add(ChatMessage('user', userContent));
      _busy = true;
      _controller.clear();
    });
    await _saveHistory();
    _jumpToBottom();

    try {
      final recent = _messages.length > 24
          ? _messages.sublist(_messages.length - 24)
          : _messages;
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/responses'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'instructions': systemPrompt,
          'input': recent.map((m) => {
            'role': m.role,
            'content': m.content,
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 90));

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = data is Map
            ? (data['error']?['message']?.toString() ?? response.body)
            : response.body;
        throw Exception(error);
      }

      String answer = '';
      if (data is Map && data['output'] is List) {
        for (final item in data['output']) {
          if (item is Map && item['content'] is List) {
            for (final part in item['content']) {
              if (part is Map && part['type'] == 'output_text') {
                answer += '${part['text'] ?? ''}';
              }
            }
          }
        }
      }
      if (answer.trim().isEmpty) {
        answer = 'وصل رد من الخدمة، لكن لم أتمكن من استخراج النص.';
      }
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage('assistant', answer)));
      await _saveHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(
          'assistant', 'حصل خطأ أثناء الاتصال: $e')));
      await _saveHistory();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _attachedText = null;
          _attachedName = null;
        });
        _jumpToBottom();
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح المحادثة؟'),
        content: const Text('سيتم حذف سجل المحادثة المحفوظ على هذا الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('مسح')),
        ],
      ),
    );
    if (ok == true) {
      setState(_messages.clear);
      await _saveHistory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(agentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(agentSubtitle, style: const TextStyle(fontSize: 11)),
          ]),
          actions: [
            IconButton(tooltip: 'إعدادات', onPressed: _settings,
                icon: const Icon(Icons.settings_outlined)),
            IconButton(tooltip: 'محادثة جديدة', onPressed: _clearChat,
                icon: const Icon(Icons.delete_outline)),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.smart_toy_outlined,
                            size: 62, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text('أهلاً بك في $agentName',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('اكتب سؤالك أو ارفع ملفاً نصياً لبدء العمل.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54)),
                      ]),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_busy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_busy && index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 760),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(msg.content,
                              textDirection: TextDirection.rtl),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_attachedName != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text(_attachedName!),
                      onDeleted: () => setState(() {
                        _attachedName = null;
                        _attachedText = null;
                      }),
                    ),
                  ),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  IconButton(
                    tooltip: 'إرفاق ملف نصي',
                    onPressed: _busy ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'إرسال',
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
