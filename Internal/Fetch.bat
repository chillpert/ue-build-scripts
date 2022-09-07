@echo off
REM Author: github.com/chillpert

REM This script sets multiple paths to important files and places, 
REM e.g. UBT, UE, UnrealEditor, and the project's path and name.
REM Do not run this script on its own.

REM Define color codes for colored output
REM Source: https://ss64.com/nt/echoansi.txt
set _red=[31m
set _green=[32m
set _yellow=[33m
set _reset=[0m

echo %_yellow%
echo Fetching project information ...
echo %_reset%

REM Search for engine using the paths in EnginePaths.txt
set ENGINE_PATHS=%SCRIPTS_PATH%\EnginePaths.txt

for /f %%i in ('git rev-parse --show-toplevel') do set GIT_ROOT_DIR=%%i

for /F "usebackq delims=" %%a in ("%ENGINE_PATHS%") do (
    if exist %%a\ (
        set ENGINE_PATH=%%a
        goto :continue
    ) else (
        echo Did not find engine in "%%a". Trying next location ...
    )
)

:continue

if not defined ENGINE_PATH (
    echo %_red%
    echo ERROR: Please install Unreal Engine. 
    echo:
    echo        If you have already installed it into a different location, 
    echo        please add your custom engine path to Scripts/EnginePaths.txt
    echo        Make sure not to include white spaces at the end of the line.
    echo %_reset%

    pause
    exit 1
)

set UBT_PATH=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe
set EDITOR_PATH=%ENGINE_PATH%\Engine\Binaries\Win64\UnrealEditor.exe

echo Engine path:  %ENGINE_PATH%
echo Editor path:  %EDITOR_PATH%
echo UBT path:     %UBT_PATH%

set BUILD_STATUS_FILE_NAME=BuildStatus.txt

rem Determine path of project and project name
call %SCRIPTS_PATH%/Internal/SetProjectPath.bat