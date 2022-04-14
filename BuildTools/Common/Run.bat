@echo off
REM Author: github.com/chillpert

echo:
echo Launching %PROJECT_NAME%
echo:

%cd%\%PROJECT_NAME%.uproject

if %ERRORLEVEL% neq 0 goto FailedLaunch

exit /b 0

:FailedLaunch

echo:
echo ERROR: Failed to launch %PROJECT_NAME%. Please make sure file extension support is installed.
echo:

pause
exit /b 1
