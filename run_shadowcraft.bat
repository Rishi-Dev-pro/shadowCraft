@echo off
setlocal EnableExtensions
title SHADOWCRAFT 2D

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
cd /d "%PROJECT_DIR%"

set "GODOT_EXE=%GODOT4_EXE%"
if defined GODOT_EXE goto :validate_engine

if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Programs\Godot\godot.exe" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\godot.exe"
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_EXE if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT_EXE if exist "%ProgramFiles%\Godot\godot.exe" set "GODOT_EXE=%ProgramFiles%\Godot\godot.exe"
if not defined GODOT_EXE for /f "delims=" %%G in ('where.exe Godot_v4.7.2-stable_win64.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"
if not defined GODOT_EXE for /f "delims=" %%G in ('where.exe godot.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Programs\Godot\godot_console.exe" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\godot_console.exe"
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64_console.exe" set "GODOT_EXE=%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT_EXE if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64_console.exe" set "GODOT_EXE=%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT_EXE for /f "delims=" %%G in ('where.exe Godot_v4.7.2-stable_win64_console.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"
if not defined GODOT_EXE for /f "delims=" %%G in ('where.exe godot_console.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"

:validate_engine
if not defined GODOT_EXE goto :engine_missing
if not exist "%GODOT_EXE%" goto :engine_missing
set "LOG_DIR=%PROJECT_DIR%\reports\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
set "LOG_FILE=%LOG_DIR%\shadowcraft_latest.log"
"%GODOT_EXE%" --headless --version > "%LOG_FILE%" 2>&1
if errorlevel 1 goto :engine_invalid
findstr /c:"4.7.2" "%LOG_FILE%" >nul
if errorlevel 1 goto :engine_invalid

echo Launching ShadowCraft 2D (Godot 4.7.2)...
echo Project: "%PROJECT_DIR%"
echo Runtime log: "%LOG_FILE%"
set "USER_ARGS="
if /i "%~1"=="debug" set "USER_ARGS=-- --combat-debug"
"%GODOT_EXE%" --path "%PROJECT_DIR%" --scene "res://scenes/ui/intro_cinematic.tscn" --log-file "%LOG_FILE%" %USER_ARGS%
set "GAME_EXIT_CODE=%ERRORLEVEL%"
if not "%GAME_EXIT_CODE%"=="0" goto :game_failed
exit /b 0

:engine_missing
echo [ERROR] Godot 4.7.2 was not found or the configured GODOT4_EXE path does not exist.
echo Set GODOT4_EXE to the Godot executable or add Godot 4.7.2 to PATH.
goto :launch_failed

:engine_invalid
echo [ERROR] The selected executable did not report Godot 4.7.2.
echo Selected: "%GODOT_EXE%"
echo Check the engine output: "%LOG_FILE%"
goto :launch_failed

:game_failed
echo [ERROR] ShadowCraft exited with code %GAME_EXIT_CODE%.
echo Godot log: "%LOG_FILE%"
goto :launch_failed

:launch_failed
echo.
echo Press any key to close this error window.
pause >nul
exit /b 1
