@echo off
setlocal
cd /d "%~dp0"
title SmartCity 360 - Run in Microsoft Edge

echo ==========================================
echo       SMARTCITY 360 - WEB LAUNCHER
echo ==========================================
echo.
where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter was not found in PATH.
  echo Add C:\flutter\bin to PATH, then reopen this window.
  pause
  exit /b 1
)
if not exist "pubspec.yaml" (
  echo ERROR: pubspec.yaml not found.
  echo Please run this file from the extracted smartcity_360_pro folder.
  pause
  exit /b 1
)
echo [1/3] Checking web platform files...
if not exist "web\index.html" (
  flutter create --platforms=web .
  if errorlevel 1 goto failed
)
echo.
echo [2/3] Getting packages...
flutter pub get
if errorlevel 1 goto failed
echo.
echo [3/3] Launching SmartCity 360 in Edge...
flutter run -d edge
if errorlevel 1 goto failed
exit /b 0
:failed
echo.
echo Flutter reported an error. Copy the first error message from this window.
pause
exit /b 1
