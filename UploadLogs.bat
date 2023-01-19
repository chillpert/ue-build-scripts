@echo off
setlocal enableDelayedExpansion

REM Author: github.com/chillpert

REM This script uploads your MyProject.log file to a new branch in your Git repo.
REM This branch can then be used to quickly access log files from anyone with contributor
REM priviliges.
REM This is useful for quickly sharing the engine's log file to speed up troubleshooting.
REM @NOTE: Currently this script is only guaranteed to work with the default
REM installation explained in the readme.

REM @NOTE: Modify this branch name to whatever you want to call your logging branch.
REM        Please publish a branch of this name first before running the script!
set BRANCH_NAME=junk/logs

set SCRIPTS_PATH=%cd%
call Internal/Fetch.bat

REM Temporarily move up to the game project's directory to retrieve its url.
pushd %cd%
call Internal/SetProjectPath.bat
cd %PROJECT_PATH%

REM Retrieve GitHub url of game repo
for /F "tokens=* USEBACKQ" %%F in (`git remote get-url origin`) do (
    set REMOTE_URL=%%F
)

popd

REM Assign a slightly unusual directory name to avoid conflicts and accidental deletion
set REPO_DIR=%PROJECT_NAME%_logs_staging

REM Clone single orphan branch called 'junk/logs'
git clone --single-branch --depth=1 --branch %BRANCH_NAME% %REMOTE_URL% %REPO_DIR%

REM Retrieve current time (will be appended to the file name of the file that will be pushed)
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set LDT=%%j
set LDT=%LDT:~0,4%-%LDT:~4,2%-%LDT:~6,2%_%LDT:~8,2%-%LDT:~10,2%-%LDT:~12,6%

REM Retrieve the name of the current git user (will also be appended to the file name of the file that will be pushed)
for /F "tokens=* USEBACKQ" %%F in (`git config user.name`) do (
    set GIT_NAME=%%F
)

REM Copy the log file 
set TARGET_NAME=%GIT_NAME%_%LDT%.log
set TARGET_LOCATION=%cd%\%REPO_DIR%\Builds\%TARGET_NAME%

REM Store the path to the engine log file
set LOG_PATH=%PROJECT_PATH%\Saved\Logs\%PROJECT_NAME%.log
copy %LOG_PATH% %TARGET_LOCATION%

REM Temporarily navigate inside of the orphan branch folder
pushd %cd%
cd %REPO_DIR%

REM We can only push when up to date
git pull --rebase

REM Stage the file, create the commit, and push it
git add Builds\%TARGET_NAME%
git commit -m "Upload build log"
git push

popd

REM Delete the folder again
rmdir /S /Q %REPO_DIR%
