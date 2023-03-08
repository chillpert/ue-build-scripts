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

rem Initialize LFS
git lfs install --force
if errorlevel 1 (
    echo %_red%
    echo Failed to initialize Git LFS. Please ask tech support for help.
    echo %_reset%

    pause
    exit 1
)

rem Enable rebase policy
git config pull.rebase true

rem Load Git aliases
git config include.path "..\.gitalias"

rem Checkout all submodules
git submodule update --init --recursive
if errorlevel 1 (
    echo %_red%
    echo Failed to update submodules. Please ask tech support for help.
    echo %_reset%

    pause
    exit 1
)

call "%SCRIPTS_PATH%/Internal/Fetch.bat"

rem Vendor / ThirdParty
call "%SCRIPTS_PATH%/Internal/Wwise.bat"

call "%SCRIPTS_PATH%/Internal/Build.bat"

call "%SCRIPTS_PATH%/Internal/Run.bat"

pause