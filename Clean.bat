@echo off
setlocal enabledelayedexpansion

REM Author: github.com/chillpert

REM --------------------------------------------------------------------------------------
REM @NOTE: Modify this according to where you cloned the ue-build-scripts repo to.
REM If you followed the instructions in the readme, then this should work out of the box.
set "SCRIPTS_PATH=%cd%\Scripts"
REM --------------------------------------------------------------------------------------

REM Define color codes for colored output
REM Source: https://ss64.com/nt/echoansi.txt
set _red=[31m
set _green=[32m
set _yellow=[33m
set _reset=[0m

REM Fetch project information
call %SCRIPTS_PATH%/Internal/Fetch.bat

REM Clean and refresh VS solution file
call %SCRIPTS_PATH%/Internal/Clean.bat
call %SCRIPTS_PATH%/Internal/GenerateProjectFiles.bat

echo %_yellow%
echo Finished cleaning build files.
echo:
echo Please run Launch.bat to start the editor.
echo %_reset%

pause
exit 0