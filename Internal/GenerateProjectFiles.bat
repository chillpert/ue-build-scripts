@echo off
REM Author: github.com/chillpert

REM This script generates Visual Studio project files for the given project.
REM Do not run this script on its own.

if exist "%PROJECT_PATH%\Source\" (
    echo %_yellow%
    echo Generating Visual Studio project files for %PROJECT_NAME% ...
    echo %_reset%

    "%UBT_PATH%" -projectfiles -Project="%PROJECT_PATH%\%PROJECT_NAME%.uproject" -game -rocket -progress

    if errorlevel 1 (
        echo %_red%
        echo Failed to generate project files for %PROJECT_NAME%.
        echo %_reset%

        pause
        exit /b 1
    )
)