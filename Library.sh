#!/usr/bin/env bash
# Author: github.com/chillpert

# This script simply provides several functions to use in other scripts.

# @TODO: Automate by looking at ProjectName.uproject
engineVersion="5.2"

# @NOTE: Change this to match your game's root directory.
#        In this case, the script repository is located directly inside
#        of the game's root directory.
projectPath="$(cd .. && pwd)"

# @NOTE: Your desired minimum Visual Studio product line version
desiredVsVersion="2022"

# @NOTE: The minimum DotNet major version required by UE5
desiredDotNetVersion=6

# @NOTE: Linux users must provide the path to their UE5 installation in a variable called 'UE_PATH'
#        Add 'export UE_Path="/my/path/to/UE"' to your '.bashrc' or '.zshrc'

# @NOTE: See 'GenerateBugReport.sh'. Set this variable there instead.
branchName="junk/logs"

scriptsPath="$(pwd)"
projectName=$(basename "$projectPath")

# Overwrite this variable after sourcing the library script to specify a different git-lfs executable.
# For example, I am using the UEGitPlugin's custom git-lfs that can lock and unlock files in parallel.
git_lfs_cmd="git lfs"

getPlatform() {
    if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        platform="Linux"
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        platform="Win64"
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

verifyVisualStudioVersion() {
    vsVersion="$(./vswhere.exe -property catalog_productLineVersion)"
    if [ $? -ne 0 ]; then
        throwError "Failed to run vswhere.exe. Check if it exists in the same directory as 'Library.sh'"
    fi

    if ! [[ "$vsVersion" = *"$desiredVsVersion"* ]]; then
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

    # Check if VS 2022 is installed (Windows only)
    if [ "$platform" = "Win64" ]; then
        verifyVisualStudioVersion

        # Check if DotNet 6.x.x or higher is installed
        verifyDotNetVersion
    fi

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
    cd "$projectPath"
    git config include.path "../.gitalias"
    cd -

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
        enginePath="$UE_PATH"
        if [ -z "$enginePath" ]; then
            throwError "Please set the path to your UE5 installation in a variable called UE_PATH. Add 'export UE_PATH=/path/to/my/ue' in your '.bashrc' or '.zshrc' and reload your environment."
        fi

    # Windows
    elif [ "$platform" = "Win64" ]; then
        # Use registry to find install location
        enginePath="$(powershell -command "(Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\\$engineVersion' -Name 'InstalledDirectory' ).'InstalledDirectory'")"
        enginePath="${enginePath//\\//}"
    else
        throwError "This platform is not supported."
    fi

    if [ -z "$enginePath" ]; then
        throwError "Please install Unreal Engine. If you have already installed it, please ask tech for help."
    fi

    if [ "$platform" = "Win64" ]; then
        editorPath="$enginePath/Engine/Binaries/Win64/UnrealEditor.exe"
        ubtPath="$enginePath/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe"
    elif [ "$platform" = "Linux" ]; then
        editorPath="$enginePath/Engine/Binaries/Linux/UnrealEditor"
        ubtPath="$enginePath/Engine/Build/BatchFiles/Linux/Build.sh"
    fi

    echo "Engine path:    $enginePath"
    echo "Editor path:    $editorPath"
    echo "UBT path:       $ubtPath"
    echo "Project path:   $projectPath"
    echo "Project name:   $projectName"

    echo
}

build() {
    if [ -z "$platform" ]; then
        throwError "This platform is not supported."
    fi

    if [ -d "$projectPath/Source" ]; then
        if ! [[ -d "$projectPath/Binaries" ]] || ! [[ -d "$projectPath/Intermediate" ]]; then
            printHeader "Generating project files ..."

            "$ubtPath" -projectFiles -Project="$projectPath/$projectName.uproject" -game -rocket -progress

            if [ $? -ne 0 ]; then
                throwError "Failed to generate project files ..."
            fi

            echo
        fi

        printHeader "Compiling C++ ..."

        "$ubtPath" Development "$platform" -Project="$projectPath/$projectName.uproject" -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE

        if [ $? -ne 0 ]; then
            echo
            printError "Failed to compile $projectName." 
            echo 

            read -p "Do you want to upload your engine log? Press 'y' to confirm or any other key to cancel. " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                uploadEngineLogs
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

    if [ "$platform" = "Win64" ]; then
        "$editorPath" "$projectPath/$projectName.uproject" &
    elif [ "$platform" = "Linux" ]; then
        "$editorPath" "$projectPath/$projectName.uproject" &
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

    logFile="${projectPath}/Saved/Logs/${projectName}.log"

    if ! [[ -f "$logFile" ]]; then
        throwError "No engine log has been created yet."
    fi

    # Retrieve GitHub url of game repo
    remoteUrl=$(git remote get-url origin)
    echo HERE: $remoteUrl

    cd - 1> /dev/null

    # Assign a slightly unusual directory name to avoid conflicts and accidental deletion
    stagingDir="${projectName}_logs_staging"

    # Clone single orphan branch called ${branchName}
    git clone --single-branch --branch "$branchName" "$remoteUrl" "$stagingDir"
    # @TODO: This check is always false 
    # if [ $? -ne 0 ]; then
    #     throwError "Failed to clone orphan branch $branchName"
    # fi

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

forceUnlockAll() {
    if [ $# -ne 1 ]; then
        echo "Please provide your project root directory as an argument."
        exit
    fi

    read -p "This function will delete all uncomitted local changes. Are you sure that you want to proceed? [yN] (enter y to confirm) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi

    cd "$1"

    locks=$(echo "$($git_lfs_cmd locks | grep -i $(git config user.name))" | awk '{print $1}')
    if [ -z "$locks" ]; then
        echo "Nothing to do"
        exit
    fi

    echo "$locks" | while read line; do
        mkdir -p $(dirname $line)
        touch $line
        git add $line -f
    done

    git commit -m "Remove locks"
    $git_lfs_cmd unlock $(echo $locks)
    git reset --hard HEAD~1

    cd -
}
