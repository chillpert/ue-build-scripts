@echo off
REM Author: github.com/chillpert

pushd %cd%
cd ..

echo:
echo Compiling %PROJECT_NAME% ...
echo: 

%UBT% Development Win64 -Project=%cd%\%PROJECT_NAME%.uproject -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE

if errorlevel 1 (
    echo %_red%
    echo Failed to compile %PROJECT_NAME%.
    echo %_reset%

    pause
    exit /b 1
)

echo:
echo Generating Visual Studio project files for %PROJECT_NAME% ...
echo:

%UBT% -projectfiles -Project=%cd%\%PROJECT_NAME%.uproject -game -rocket -progress

if errorlevel 1 (
    echo %_fRed%
    echo Failed to generate project files for %PROJECT_NAME%.
    echo %_RESET%

    pause
    exit /b 1
)

popd