#!/usr/bin/env bash
# Author: github.com/chillpert

# This script simply provides several functions to use in other scripts.

# @TODO: Automate by looking at ProjectName.uproject
engineVersion="5.1"

# @NOTE: Change this to match your game's root directory.
#        In this case, the script repository is located directly inside
#        of the game's root directory.
projectPath="$(cd .. && pwd)"

# For Linux users only (change here if you are using a wrapper for ue4cli)
ue4cli="~/.local/bin/ue4"

scriptsPath="$(pwd)"
projectName="$(basename \"$projectPath\")"

getPlatform() {
    if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        platform="Linux"
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        platform="Windows"
    else
        throwError "This platform is not supported."
    fi
}

waitForInput() {
    read -p "Press ENTER to continue ..."
}

printError() {
    echo -e "\e[31m$1\e[0m"
}

printWarning() {
    echo -e "\e[33m$1\e[0m"
}

printSuccess() {
    echo -e "\e[32m$1\e[0m"
}

printHeader() {
    banner="=========================================="
    echo -e "\e[33m${banner}\n$1\n${banner}\e[0m\n"
}

throwError() {
    echo
    printError "$1"
    echo

    waitForInput
    exit 1
}

verifyWwiseInstallation() {
    if ! [[ -d "$projectPath/Plugins/Wwise/ThirdParty" ]]; then
        printError "You are missing some Wwise files"
        echo
        echo "Please download 'Wwise.zip' from our Google Drive under 'ThirdParty/Wwise/Wwise.zip' or use the link below."
        echo "https://drive.google.com/drive/folders/1fpE5fukgSOYWELKkQLsyChV0LY0EglyL?usp=share_link"
        echo
        echo "Now extract the zip and you will get a folder called 'ThirdParty'."
        echo "Place this folder in 'Plugins/Wwise'. This folder is located in the game's repository."
        echo
        echo "Simply re-launch this script again and you should be able to successfully compile Wwise."
        echo 

        waitForInput
        exit 1
    fi
}

checkDependencies() {
    printHeader "Checking dependencies"

    # Git
    if ! [ -x "$(command -v git)" ]; then
        throwError "Please install Git and try again."
    fi

    # Git-LFS
    if ! [ -x "$(command -v git-lfs)" ]; then
        throwError "Please install Git-LFS 2 and try again."
    fi

    getPlatform

    # ue4-cli for Linux
    if [ "$platform" = "Linux" ]; then
        if ! [ -x "$(command -v $ue4cli)" ]; then
            throwError "Please install ue4-cli."
        fi
    fi

    # Check if Wwise SDK binaries exist
    verifyWwiseInstallation

    echo
}

prepare() {
    printHeader "Preparing repository ..."

    # Initialize LFS
    git lfs install --force
    if [ $? -ne 0 ]; then
        throwError "Failed to initialize Git LFS. Please ask tech for help." 
    fi

    # Set rebase policy
    git config pull.rebase true

    # Load Git aliases
    git config include.path "../.gitalias"

    # Checkout all submodules
    git submodule update --init --recursive
    if [ $? -ne 0 ]; then
        throwError "Failed to update submodules. Please ask tech for help."
    fi

    echo
}

fetch() {
    printHeader "Fetching project information ..."

    enginePaths="${scriptsPath}/EnginePaths.txt"

    # Determine where UE is installed on this machine (Windows only)
    # Linux
    if [ "$platform" = "Linux" ]; then
        throwError "Linux support is not implemented yet."
    # Windows
    elif [ "$platform" = "Windows" ]; then
        # Use registry to find install location
        # enginePath=$(cmd.exe /c "powershell -command \"& { (Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\\$engineVersion' -Name 'InstalledDirectory' ).'InstalledDirectory' }\"")
        enginePath=$(powershell -command "powershell -command \"& { (Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\5.1' -Name 'InstalledDirectory' ).'InstalledDirectory' }\"")

        enginePath="${enginePath//\\//}"
    else
        throwError "This platform is not supported."
    fi

    if [ -z "$enginePath" ]; then
        throwError "Please install Unreal Engine. If you have already installed it, please ask tech for help."
    fi

    ubtPath="$enginePath/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe"
    editorPath="$enginePath/Engine/Binaries/Win64/UnrealEditor.exe"

    echo "Engine path:    $enginePath"
    echo "Editor path:    $editorPath"
    echo "UBT path:       $ubtPath"
    echo "Project path:   $projectPath"
    echo "Project name:   $projectName"

    echo
}

build() {
    if [ -d "$projectPath/Source" ]; then
        if ! [[ -d "$projectPath/Binaries" ]] || ! [[ -d "$projectPath/Intermediate" ]] || ! [[ -f "$projectPath/$projectName.sln" ]]; then
            printHeader "Generating project files ..."

            if [ "$platform" = "Windows" ]; then
                "$ubtPath" -projectFiles -Project="$projectPath/$projectName.uproject" -game -rocket -progress
            elif [ "$platform" = "Linux" ]; then
                $ue4cli gen
            else
                throwError "This platform is not supported."
            fi

            if [ $? -ne 0 ]; then
                throwError "Failed to generate project files ..."
            fi
        fi

        printHeader "Compiling C++ ..."

        if [ "$platform" = "Windows" ]; then
            "$ubtPath" Development Win64 -Project="$projectPath/$projectName.uproject" -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE
        elif [ "$platform" = "Linux" ]; then
            $ue4cli build
        else
            throwError "This platform is not supported."
        fi

        if [ $? -ne 0 ]; then
            echo
            printError "Failed to compile $projectName." 
            echo 

            read -p "Do you want to upload your engine log? Press 'y' to confirm or any other key to cancel. " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                "$scriptsPath/GenerateBugReport.sh"
                exit 1
            else 
                exit 1
            fi
        fi
    fi
    
    echo
}

run() {
    printHeader "Launching $projectName"
    echo "The editor might launch silently, so please give it a few minutes."

    if [ "$platform" = "Windows" ]; then
        "$editorPath" "$projectPath/$projectName.uproject" &
    elif [ "$platform" = "Linux" ]; then
        cd "$projectPath" && $ue4cli run
    else
        throwError "This platform is not supported."
    fi

    if [ $? -ne 0 ]; then
        throwError "Failed to launch UnrealEditor."
    fi
}
