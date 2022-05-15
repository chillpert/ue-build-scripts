@echo off
REM Author: github.com/chillpert

echo:
echo Launching %PROJECT_NAME%
echo:

REM Launch project
start "UnrealEditor" "%EDITOR_PATH%" "%PROJECT_PATH%%PROJECT_NAME%.uproject"

REM Alternative way of launching the project
REM %cd%\..\%PROJECT_NAME%.uproject

REM if %ERRORLEVEL% neq 0 goto FailedLaunch

exit /b 0

REM Only necessary to run when using the alternative way of launching the project
:FailedLaunch

echo:
echo ERROR: Failed to launch %PROJECT_NAME%. Please make sure file extension support is installed.
echo:

pause
exit /b 1
