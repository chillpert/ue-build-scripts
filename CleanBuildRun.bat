@echo off
setlocal enableDelayedExpansion

REM Author: github.com/chillpert

call Common/Config.bat
call Common/Clean.bat
call Common/Build.bat
call Common/Run.bat