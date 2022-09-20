@echo off
REM Author: github.com/chillpert

REM This build compiles the given project in the development configuration.
REM Do not run this script on its own.

if exist "%PROJECT_PATH%\Source\" (
    echo %_yellow%
    echo Compiling C++ ...
    echo %_reset%

    "%UBT_PATH%" Development Win64 -Project="%PROJECT_PATH%\%PROJECT_NAME%.uproject" -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE
    if errorlevel 1 (
        REM @TODO: Colored output doesn't work for some reason because of the command above
        echo:
        echo =========================================================================================================
        echo Failed to compile %PROJECT_NAME%. Please run "%SCRIPTS_PATH%\UploadLogs.bat".
        echo =========================================================================================================
        echo:

        pause
        exit 1
    )

    REM Clear build status
    git update-index --assume-unchanged %SCRIPTS_PATH%/BuildStatus.txt
    echo None > "%SCRIPTS_PATH%\%BUILD_STATUS_FILE_NAME%"
)

echo %_yellow%
echo Compiling all BPs ...%_reset%

REM Launch a headless version of UnrealEditor that comiles all blueprints
start /WAIT /MIN "UE-Headless-Compile-All-BPs" "%EDITOR_PATH%" "%PROJECT_PATH%\%PROJECT_NAME%.uproject" -run=CompileAllBlueprints -nullrhi