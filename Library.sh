#!/usr/bin/env bash
# Author: github.com/chillpert

# This script simply provides several functions to use in other scripts.

# @TODO: Automate by looking at ProjectName.uproject
engineVersion="5.1"

# @NOTE: Change this to match your game's root directory.
#        In this case, the script repository is located directly inside
#        of the game's root directory.
projectPath="$(cd .. && pwd)"

# @NOTE: Your desired minimum Visual Studio product line version
desiredVsVersion="2022"

# @NOTE: The minimum DotNet major version required by UE5
desiredDotNetVersion=6

# For Linux users only (change here if you are using a wrapper for ue4cli)
ue4cli="~/.local/bin/ue4"

# @NOTE: Modify this to match your desired branch to store log files. This is r
branchName="junk/logs"

scriptsPath="$(pwd)"
projectName=$(basename "$projectPath")

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

# @NOTE: This is very specific so most likely you won't need this.
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

verifyVisualStudioVersion() {
    vsVersion="$(./vswhere.exe -property catalog_productLineVersion)"
    if [ $? -ne 0 ]; then
        throwError "Failed to run vswhere.exe. Check if it exists in the same directory as 'Library.sh'"
    fi

    if ! [[ "$vsVersion" = "$desiredVsVersion" ]]; then
        throwError "Please install Visual Studio Community 2022 and try again."
    fi
}

verifyDotNetVersion() {

    if ! [ -x "$(command -v dotnet)" ]; then
        throwError "Please install DotNet $desiredDotNetVersion.x.x or higher and try again."
    else
        # @TODO: String to int comparisons should be simpler than this!
        dotNetVersion="$(dotnet --version)"
        dotNetVersion=${dotNetVersion%.*}
        dotNetVersion=${dotNetVersion%.*}
        if [ $dotNetVersion -lt $desiredDotNetVersion ]; then
            throwError "Please update your DotNet installation to version $desiredDotNetVersion.x.x or higher and try again."
        fi
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

    # Check if VS 2022 is installed (Windows only)
    if [ "$platform" = "Windows" ]; then
        verifyVisualStudioVersion
    fi

    # Check if DotNet 6.x.x or higher is installed
    verifyDotNetVersion

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

uploadEngineLogs() {
    printHeader "Uploading engine log"

    cd "$projectPath"
    git ls-remote --exit-code --heads origin $branchName
    if [ $? -ne 0 ]; then
        throwError "Failed to upload engine log: The branch $branchName does not exist on the remote. Please create it first and try again."
    fi
    cd - 1> /dev/null

    scriptsPath="basename $(pwd)"
    projectPath="$(cd .. && pwd)"

    projectName=$(cd .. && basename $(pwd))
    logFile="../Saved/Logs/${projectName}.log"

    if ! [[ -f "$logFile" ]]; then
        throwError "No engine log has been created yet."
    fi

    # Retrieve GitHub url of game repo
    remoteUrl=$(cd .. && git remote get-url origin)

    # Assign a slightly unusual directory name to avoid conflicts and accidental deletion
    stagingDir="${projectName}_logs_staging"

    # Clone single orphan branch called ${branchName}
    git clone --single-branch --depth=1 --branch "$branchName" "$remoteUrl" "$stagingDir"
    if [ $? -ne 0 ]; then
        throwError "Failed to clone orphan branch $branchName"
    fi

    # Retrieve current time
    localTime=$(date)

    # Retrieve Git user name
    gitUserName=$(git config user.name)

    # Create the target directory for copying
    mkdir -p "${stagingDir}/Logs"

    # Copy the log file
    cp "$logFile" "${stagingDir}/Logs/${gitUserName}_${localTime}"

    # Enter the directory of the orphan branch
    cd "$stagingDir"

    # Make sure the local orphan branch is up to date
    git pull --rebase

    # Stage, commit, and push the log file
    git add --all
    git commit -m "Upload engine log"
    git push

    # Keep track of that commit
    logCommitInfo="$(git log -1 --oneline)
$(git config --get remote.origin.url | sed -e 's/\.git$//g')/commit/$(git rev-parse HEAD)"

    # Go back to the previous directory
    cd -

    # Delete the local folder of the orphan branch
    rm -rf $stagingDir

    echo
}

# @NOTE: Requires uploadEngineLogs to be run before executing this function
generateBugReport () {
    printHeader "Generating bug report and copying to clipboard ..."

    cd ..
    commitInfo="$(git log -1 --oneline)
$(git config --get remote.origin.url | sed -e 's/\.git$//g')/commit/$(git rev-parse HEAD)"
    cd - 1> /dev/null

    echo "### Description:
*[Optional] If the title is not enough add more information here.*

### Steps to reproduce:
1.
2.
3.

### Screenshot or video:
*[Optional]*

### Expected behavior:
*Describe what behavior you were expecting. In other words, what should have happened if there was no bug.*

### Branch and commit:
${commitInfo}

### Logs:
${logCommitInfo}" | clip
}

cleanBuildFiles() {
    printHeader "Cleaning $projectName build files ..."

    rm -rf "$projectPath/Binaries" "$projectPath/Intermediate" "$projectPath/*.sln"

    printWarning "Now you may run 'Launch.sh' again."
    echo 
}