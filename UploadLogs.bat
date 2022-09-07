@echo off
setlocal enableDelayedExpansion

REM Author: github.com/chillpert

call Common/Config.bat

if errorlevel 1 (
    pause
    exit /b 1
)

REM Retrieve GitHub url of game repo
for /F "tokens=* USEBACKQ" %%F in (`git remote get-url origin`) do (
set REMOTE_URL=%%F
)

REM Assign a slightly unusual directory name to avoid conflicts and accidental deletion
set REPO_DIR=%PROJECT_NAME%_logs_staging

git clone --single-branch --depth=1 --branch junk/logs %REMOTE_URL% %REPO_DIR%

set LOG_PATH=%cd%\..\Saved\Logs\%PROJECT_NAME%.log

for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set LDT=%%j
set LDT=%LDT:~0,4%-%LDT:~4,2%-%LDT:~6,2%_%LDT:~8,2%-%LDT:~10,2%-%LDT:~12,6%

for /F "tokens=* USEBACKQ" %%F in (`git config user.name`) do (
set GIT_NAME=%%F
)

set TARGET_NAME=%GIT_NAME%_%LDT%.log
set TARGET_LOCATION=%cd%\%REPO_DIR%\Builds\%TARGET_NAME%

copy %LOG_PATH% %TARGET_LOCATION%

pushd %cd%

cd %REPO_DIR%

git pull --rebase

git add Builds\%TARGET_NAME%
git commit -m "Upload build log"
git push

popd

rmdir /S /Q %REPO_DIR%
