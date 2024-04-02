#!/usr/bin/env bash
# Author: github.com/chillpert

# This script simply provides several functions to use in other scripts.

# @TODO: Automate by looking at ProjectName.uproject
engineVersion="5.3"

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
    elif [ "$(expr substr $(uname -s) 1 10)" == "MSYS_NT-10" ]; then
        platform="Win64"
    else
        throwError "This platform is not supported."
    fi
}

copyToClipboard() {
    getPlatform

    if [ "$platform" = "Win64" ]; then
        echo "$1" | clip
    elif [ "$platform" = "Linux" ]; then
        echo "$1" | xclip -selection c
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

fetchCustomGitLFS() {
    getPlatform

    if [ -d "Plugins/UEGitPlugin" ]; then
        if [ "$platform" = "Win64" ]; then
            if [ -f "Plugins/UEGitPlugin/git-lfs.exe" ]; then
                git_lfs_cmd="Plugins/UEGitPlugin/git-lfs.exe"
                printSuccess "Found custom LFS executable (Windows)"
            fi
        elif [ "$platform" = "Linux" ]; then
            if [ -f "Plugins/UEGitPlugin/git-lfs" ]; then
                git_lfs_cmd="Plugins/UEGitPlugin/git-lfs"
                printSuccess "Found custom LFS executable (Linux)"
            fi
        fi
    fi
}

verifyVisualStudioVersion() {
    vsVersion="$(./ThirdParty/vswhere.exe -property catalog_productLineVersion -prerelease)"
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

    cd "$projectPath"
    
    # Initialize LFS
    git lfs install --force
    if [ $? -ne 0 ]; then
        throwError "Failed to initialize Git LFS. Please ask tech for help." 
    fi
    
    # Set rebase policy
    git config pull.rebase true

    # LF (Unix, Mac) - CRLF (Windows) policy
    git config core.autocrlf true
    
    # Load custom git hooks
    git config core.hooksPath ".git/hooks"
    if [ $? -ne 0 ]; then
        throwError "Failed to set custom git hooks path. Please try updating your git installation."
    fi
    
    # Make sure hooks are available
    git lfs update --force

    # Load Git aliases
    git config include.path "../.gitalias"

    # Checkout all submodules
    git submodule update --init --recursive
    if [ $? -ne 0 ]; then
        throwError "Failed to update submodules. Please ask tech for help."
    fi
    
    cd -

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

    output="### Description:
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
${logCommitInfo}"

    copyToClipboard "$output"

}

cleanBuildFiles() {
    printHeader "Cleaning $projectName build files ..."

    rm -rf "$projectPath/Binaries" "$projectPath/Intermediate" "$projectPath/*.sln"

    printWarning "Now you may run 'Launch.sh' again."
    echo 
}

unlockAll() {
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

    fetchCustomGitLFS

    git commit -m "Remove locks"
    $git_lfs_cmd unlock $(echo $locks)
    git reset --hard HEAD~1


    copyToClipboard "git lfs lock \"$locks\" | clip"

    cd -
}

unlockUsage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " -a, --all        Removes all of your locks"
    echo " -c, --clean      Removes all of your locks even if the associated file does not exist on the currently checked out branch (-c implies -a)"
    echo " -f, --force      Removes all locks by force (for administrators only)"
}

# In Git bash for windows, pipes and fzf do not work. This is a workaround from https://github.com/junegunn/fzf/issues/2798#issuecomment-1229376159
fzfWinWrapper() {
    set -eo pipefail

    # @TODO: This will not work all the time as it assumes this repo to be checkout out in a folder called Scripts instead of the native repo name.
    fzf="$(pwd)/Scripts/ThirdParty/fzf.exe"

    prefix="$(basename "${BASH_SOURCE:-$0}")-${UID:-$(id -u)}"
    tmpdir=$(mktemp -dp "${TMPDIR:-/tmp}" "${prefix}.XXXXX")
    trap "rm -rf -- '${tmpdir}'" EXIT

    args=
    [[ $# -ge 1 ]] && args=$(printf ' %q' "$@")

    if [[ -t 0 ]]; then
        winpty </dev/tty >/dev/tty -- bash -c \
            "command $fzf${args} >'${tmpdir}'/output"
        cat "${tmpdir}"/output
    else
        cat - >"${tmpdir}"/input
        winpty </dev/tty >/dev/tty -- bash -c \
            "command $fzf${args} <'${tmpdir}'/input >'${tmpdir}'/output"
        cat "${tmpdir}"/output
    fi
}

fetchFzfCmd() {
    getPlatform

    if [ "$platform" = "Win64" ]; then
        fzf_cmd="fzfWinWrapper"
	    
    elif [ "$platform" = "Linux" ]; then
        fzf_cmd="Scripts/ThirdParty/fzf"
    fi
}

lock() {
    # Handle no input (launch fzf to allow for locking)
    if [[ -z "$input" ]]; then
        # Try to check if custom LFS exists
        fetchCustomGitLFS

        # By default append unlock flag
        git_lfs_cmd_internal="${git_lfs_cmd} lock"

        fetchFzfCmd

        # Get all uassets in Content directory
        selected_files="$(find Content/ -name '*.uasset' | awk '{print $1}' | "$fzf_cmd" --multi)"
        if [[ -n "$selected_files" ]]; then
            # Switch end of lines with white spaces
            selected_files=$(echo "$selected_files" | tr -s '\n' ' ')

            eval "$git_lfs_cmd_internal" "$selected_files"
            exit
        fi

        exit
    fi

    files_to_lock=""

    # Only process any input that is a file
    for file in "$@"
    do
        if [[ -f "$file" ]]; then
            files_to_lock="${files_to_lock} $file"
        fi
    done

    # Do not need to proceed if no locks exist
    if [[ -z "$files_to_lock" ]]; then
        echo "Nothing to do"
        exit
    fi

    fetchCustomGitLFS

    eval "$git_lfs_cmd" lock "$files_to_lock"
}

unlock() {
    # if [ $# -ne 1 ]; then
    #     echo "Please provide your project root directory as an argument."
    #     exit
    # fi
    
    # Store unprocessed input parameters
    input="$@"

    # Try to check if custom LFS exists
    fetchCustomGitLFS

    # By default append unlock flag
    git_lfs_cmd_internal="${git_lfs_cmd} unlock"

    # Process possible flags
    while [ $# -gt 0 ]; do
        case $1 in
            -h | --help)
                unlockUsage
                exit 0
                ;;
            -a | --all)
                all="true"
                ;;
            -c | --clean*)
                clean="true"
                ;;
            -f | --force*)
                # Append force flag to our command
                git_lfs_cmd_internal="${git_lfs_cmd_internal} --force"
                ;;
        esac
        shift
    done

    # Handle unlocking all but also unlock non-existent files
    if [[ -n "$clean" ]]; then
        echo clean remove
        unlockAll "$1"
        exit
    fi

    # Handle unlocking all
    if [[ -n "$all" ]]; then
        echo "unlocking all ..."
        locks="$($git_lfs_cmd locks | grep -i $(git config user.name) | awk '{print $1}')"

        # Do not need to proceed if no locks exist
        if [[ -z "$locks" ]]; then
            echo "Nothing to do"
            exit
        fi

        # Switch end of lines with white spaces
        locks=$(echo "$locks" | tr -s '\n' ' ')

        # Perform unlocking
        eval "$git_lfs_cmd_internal" "$locks"
        exit
    fi

    # Handle no input (launch fzf to allow for unlocking)
    if [[ -z "$input" ]]; then
        fetchFzfCmd

        # Get the users locked files via fzf
        selected_files="$($git_lfs_cmd locks | grep -i $(git config user.name) | awk '{print $1}' | "$fzf_cmd" --multi)"
        if [[ -n "$selected_files" ]]; then
            # Switch end of lines with white spaces
            selected_files=$(echo "$selected_files" | tr -s '\n' ' ')

            eval "$git_lfs_cmd_internal" "$selected_files"
            exit
        fi

        exit
    fi

    
    # Only process any input that is a file
    files_to_unlock=""

    for file in ${input}; do
        if [[ -f "$file" ]]; then
            files_to_unlock="${files_to_unlock} $file"
        fi
    done

    # Do not need to proceed if no locks exist
    if [[ -z "$files_to_unlock" ]]; then
        echo "Nothing to do"
        exit
    fi

    # Default: No flags were specified so assume all given inputs are files
    eval "$git_lfs_cmd_internal" "$files_to_unlock"
}
