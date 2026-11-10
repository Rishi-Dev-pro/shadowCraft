@echo off
setlocal
title SHADOWCRAFT 2D - Combat Test Arena

set "PROJECT_DIR=%~dp0"
set "GODOT_EXE=%LOCALAPPDATA%\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" set "GODOT_EXE=godot.exe"

if /i "%GODOT_EXE%"=="godot.exe" (
	where godot.exe >nul 2>nul
	if errorlevel 1 (
		echo [ERROR] Godot 4.7.2 was not found.
		echo Install it under %%LOCALAPPDATA%%\Programs\Godot or add godot.exe to PATH.
		pause
		exit /b 1
	)
)

set "USER_ARGS="
if /i "%~1"=="debug" set "USER_ARGS=-- --combat-debug"

start "" "%GODOT_EXE%" --path "%PROJECT_DIR%" "res://scenes/arenas/combat_test_arena.tscn" %USER_ARGS%
endlocal
