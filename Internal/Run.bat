@echo off
REM Author: github.com/chillpert

REM This script simply launches your project without having to open the Epic Games Launcher.
REM Do not run this script on its own.

echo %_yellow%
echo Launching %PROJECT_NAME% ...
echo %_reset%
echo The editor might launch silently, so please wait a minute before trying again.
echo:

REM Launch project
start "UnrealEditor" "%EDITOR_PATH%" "%PROJECT_PATH%\%PROJECT_NAME%.uproject"