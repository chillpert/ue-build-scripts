@echo off
REM Author: github.com/chillpert

REM This build compiles the given project in the development configuration.
REM Do not run this script on its own.

if exist "%PROJECT_PATH%\Source\" (
    echo %_yellow%
    echo Compiling %PROJECT_NAME% ...
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
    echo None > "%PROJECT_PATH%\Source\%BUILD_STATUS_FILE_NAME%"
)