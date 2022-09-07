@echo off
setlocal enableDelayedExpansion

REM Author: github.com/chillpert

REM Fetch project information
call %SCRIPTS_PATH%/Internal/Fetch.bat

REM If build_status.txt has not been generated yet, we can just launch the project
if not exist "%PROJECT_PATH%\Source\%BUILD_STATUS_FILE_NAME%" goto Run

REM Read the current build status
set /p build_status=< "%PROJECT_PATH%\Source\%BUILD_STATUS_FILE_NAME%"

REM Check build status
if "%build_status%" == "CleanBuild" goto CleanBuild
if "%build_status%" == "Build" goto Build

goto Run

:CleanBuild
call %SCRIPTS_PATH%/Internal/Clean.bat
call %SCRIPTS_PATH%/Internal/GenerateProjectFiles.bat

:Build
call %SCRIPTS_PATH%/Internal/Build.bat

:Run
call %SCRIPTS_PATH%/Internal/Run.bat
