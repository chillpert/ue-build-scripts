@echo off
setlocal enableDelayedExpansion

REM Author: github.com/chillpert

call Common/Config.bat

if errorlevel 1 (
    pause
    exit /b 1
)

call Common/Clean.bat

call Common/Build.bat

if errorlevel 1 (
    pause
    exit /b 1
)
