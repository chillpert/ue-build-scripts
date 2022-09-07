@echo off
REM Author: github.com/chillpert

pushd %cd%
cd ..

set BUILD_FILES= "%cd%\Binaries" "%cd%\Intermediate"

(for %%a in (%BUILD_FILES%) do (
    if exist %%a\ (
        set "needsCleaning=y"
    ) 
))

if defined needsCleaning (
    echo:
    echo Cleaning %PROJECT_NAME% build files ...
    
    rmdir /S /Q Binaries >nul 2>&1 
    rmdir /S /Q Intermediate >nul 2>&1
    rmdir /S /Q .vscode >nul 2>&1
    rmdir /S /Q .vs >nul 2>&1
    del *.sln >nul 2>&1
) else (
    echo:
    echo Nothing to clean ... 
)

popd