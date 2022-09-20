@echo off
setlocal enableDelayedExpansion

REM Author: github.com/chillpert

REM Fetch project information
call %SCRIPTS_PATH%/Internal/Fetch.bat

REM If build_status.txt does not exist, simply generate it and set to perform a rebuild
if not exist "%SCRIPTS_PATH%\%BUILD_STATUS_FILE_NAME%" (
    echo CleanBuild > "%SCRIPTS_PATH%\%BUILD_STATUS_FILE_NAME%"
)

REM Read the current build status
set /p build_status=< "%SCRIPTS_PATH%\%BUILD_STATUS_FILE_NAME%"

REM Check build status
if %build_status% == CleanBuild goto CleanBuild
if %build_status% == Build goto Build

goto Run

:CleanBuild
call %SCRIPTS_PATH%/Internal/Clean.bat
call %SCRIPTS_PATH%/Internal/GenerateProjectFiles.bat

:Build
call %SCRIPTS_PATH%/Internal/Build.bat

:Run
call %SCRIPTS_PATH%/Internal/Run.bat
