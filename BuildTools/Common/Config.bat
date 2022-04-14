@echo off
REM Author: github.com/chillpert

pushd %cd%
cd ..

for %%f in (*.uproject) do (
    set "PROJECT_NAME=%%~nf"
)

popd

set "ENGINE_PATHS=%cd%\EnginePaths.txt"

for /F "usebackq delims=" %%a in ("%ENGINE_PATHS%") do (
    if exist %%a\ (
        set ENGINE_PATH=%%a
        goto :continue
    ) else (
        echo Did not find engine in "%%a"
    )
)

:continue

if not defined ENGINE_PATH (
    echo:
    echo ERROR: Please install Unreal Engine. 
    echo:
    echo        If you have already installed it into a different location, please add your path to BuildTools/EnginePaths.txt
    echo        Make sure not to include white spaces at the end of the line.
    echo:
    echo:       In this case, create a new separate commit with the following message:
    echo:           Update EnginePaths.txt
    echo:
    exit /b 1
)

echo Found engine in %ENGINE_PATH%

set ENGINE_PATH=%ENGINE_PATH:"=%
set UBT="%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
