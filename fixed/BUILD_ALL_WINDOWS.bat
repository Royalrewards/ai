@echo off
setlocal
cd /d "%~dp0"
set NOPAUSE=1
set "OUT=%~dp0OUTPUT"

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter is not installed or not in PATH. Run CHECK_SETUP_WINDOWS.bat first.
  pause
  exit /b 1
)

call "%~dp0Coffee_Business_Agent\build_all.bat"
if errorlevel 1 goto failed
call "%~dp0Mechatronics_Engineer_Agent\build_all.bat"
if errorlevel 1 goto failed

echo.
echo Collecting outputs into %OUT% ...
if not exist "%OUT%" mkdir "%OUT%"
call :collect Coffee_Business_Agent
call :collect Mechatronics_Engineer_Agent

echo.
echo SUCCESS: all 4 apps built. Open the OUTPUT folder.
explorer "%OUT%"
pause
exit /b 0

:collect
copy /y "%~dp0%~1\build\app\outputs\flutter-apk\app-release.apk" "%OUT%\%~1.apk" >nul
xcopy /e /i /y /q "%~dp0%~1\build\windows\x64\runner\Release" "%OUT%\%~1_Windows\" >nul
exit /b 0

:failed
echo.
echo BUILD FAILED. Read the error above.
pause
exit /b 1
