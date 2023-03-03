@echo off
REM Author: github.com/chillpert

if not exist "%PROJECT_PATH%\Plugins\Wwise\ThirdParty" (
    echo %_red%
    echo You are missing some Wwise files.
    echo
    echo Please download `Wwise.zip` from our Google Drive under `ThirdParty/Wwise/Wwise.zip` or use the link below.
    echo https://drive.google.com/drive/folders/1fpE5fukgSOYWELKkQLsyChV0LY0EglyL?usp=share_link
    echo
    echo Now extract the zip and you will get a folder called `ThirdParty`.
    echo Place this folder in `Plugins/Wwise` (this folder is in the game's repository).
    echo 
    echo Simply re-launch this script again and you should be able to successfully compile Wwise.
    echo 
    echo %_reset%

    pause
    exit 1
)