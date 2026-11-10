@echo off
setlocal
title SHADOWCRAFT 2D - Combat Test Arena

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "GODOT_EXE=%GODOT4_EXE%"

if not defined GODOT_EXE set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\godot.exe"
if not exist "%GODOT_EXE%" set "GODOT_EXE=%LOCALAPPDATA%\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" set "GODOT_EXE=%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" set "GODOT_EXE=%ProgramFiles%\Godot\godot.exe"

if not exist "%GODOT_EXE%" (
	set "GODOT_EXE="
	for /f "delims=" %%G in ('where.exe Godot_v4.7.2-stable_win64.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"
)
if not defined GODOT_EXE (
	for /f "delims=" %%G in ('where.exe godot.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"
)

if not defined GODOT_EXE (
	echo [ERROR] Godot was not found. Set GODOT4_EXE or add Godot to PATH.
	exit /b 1
)
if not exist "%GODOT_EXE%" (
	echo [ERROR] The configured Godot executable does not exist: "%GODOT_EXE%"
	exit /b 1
)

set "USER_ARGS="
if /i "%~1"=="debug" set "USER_ARGS=-- --combat-debug"

"%GODOT_EXE%" --path "%PROJECT_DIR%" --scene "res://scenes/arenas/combat_test_arena.tscn" %USER_ARGS%
endlocal & exit /b %ERRORLEVEL%
