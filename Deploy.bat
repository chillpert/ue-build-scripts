@echo off

REM Author: github.com/chillpert

REM This script needs to be run from inside its actual location. In other words,
REM just double-click it.

set SCRIPTS_PATH=%cd%
call %SCRIPTS_PATH%/Internal/Fetch.bat

xcopy /Y Launch\Launch.bat %PROJECT_PATH%