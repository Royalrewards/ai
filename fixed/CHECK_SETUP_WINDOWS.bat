@echo off
where flutter
if errorlevel 1 (
  echo Flutter is missing from PATH.
  pause
  exit /b 1
)
call flutter --version
call flutter doctor -v
echo.
echo Required:
echo  1) Visual Studio 2022 - "Desktop development with C++" (also tick "C++ ATL for latest build tools").
echo  2) Android Studio + Android SDK, then run: flutter doctor --android-licenses
echo  3) Windows Developer Mode ON (Settings ^> For developers) - needed by plugins.
echo  4) Keep the project path short, no spaces and no Arabic letters (e.g. C:\agents).
pause
