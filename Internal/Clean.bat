@echo off
REM Author: github.com/chillpert

REM This script simply deletes temporary build files.
REM Do not run this script on its own.

echo %_yellow%
echo Cleaning %PROJECT_NAME% build files ...%_reset%

rmdir /S /Q Binaries >nul 2>&1 
rmdir /S /Q Intermediate >nul 2>&1
rmdir /S /Q .vscode >nul 2>&1
rmdir /S /Q .vs >nul 2>&1
del *.sln >nul 2>&1
