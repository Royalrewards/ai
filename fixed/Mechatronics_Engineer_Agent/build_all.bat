@echo off
setlocal
cd /d "%~dp0"
set "PKG=mechatronics_engineer_agent"
set "LABEL=Mechatronics Engineer Agent"
set "MODE=%~1"
if "%MODE%"=="" set "MODE=all"

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter is not installed or not in PATH.
  goto failed
)

echo === [1/5] Creating platform folders ===
call flutter create --platforms=android,windows --project-name %PKG% --org com.myagents .
if errorlevel 1 goto failed

echo === [2/5] Patching Android manifest (INTERNET permission) ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch_android.ps1" -Label "%LABEL%"
if errorlevel 1 goto failed
if exist "test\widget_test.dart" del /q "test\widget_test.dart"

echo === [3/5] Getting packages ===
call flutter pub get
if errorlevel 1 goto failed

if /i "%MODE%"=="windows" goto win
echo === [4/5] Building Android APK ===
call flutter build apk --release
if errorlevel 1 goto failed
if /i "%MODE%"=="android" goto done

:win
echo === [5/5] Building Windows ===
call flutter build windows --release
if errorlevel 1 goto failed

:done
echo.
echo SUCCESS: %LABEL%
if not defined NOPAUSE pause
exit /b 0

:failed
echo.
echo FAILED: %LABEL% - read the error above.
if not defined NOPAUSE pause
exit /b 1
