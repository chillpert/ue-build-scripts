@echo off
REM Author: github.com/chillpert

pushd %cd%
cd ..

echo:
echo Compiling %PROJECT_NAME% ...
echo: 

%UBT% Development Win64 -Project=%cd%\%PROJECT_NAME%.uproject -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE

echo:
echo Generating Visual Studio project files for %PROJECT_NAME% ...
echo:

%UBT% -projectfiles -Project=%cd%\%PROJECT_NAME%.uproject -game -rocket -progress

popd