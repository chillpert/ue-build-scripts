@echo off
REM Author: github.com/chillpert

REM This script searches for a folder that contains a .uproject file.
REM It will start checking the current directory and continue looking
REM in the next higher-up directory.
REM Do not run this script on its own.

REM Determine project path
set last_dir=%cd%

:loop
for %%f in (*.uproject) do (
    set PROJECT_NAME=%%~nf
    set PROJECT_PATH=%cd%
    goto success
)

set temp_dir=%cd%
cd ..
REM If the last and the current directory are identical, we have reached the lowest level directory
if "%temp_dir%" == "%cd%" (
    goto failure
)

goto loop

:failure
echo %_red%ERROR: Make sure this script is somewhere inside of your actual game project.%_reset%
pause
exit 1

:success
echo Project path: %PROJECT_PATH%
echo Project name: %PROJECT_NAME%

REM Return to the original directory
cd %last_dir%