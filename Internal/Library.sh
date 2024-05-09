#!/usr/bin/env bash
# Author: github.com/chillpert

######################################################################################################
################################## Provide default values ############################################
######################################################################################################
# @NOTE: You can overwrite these values in your instigator script:
#        export UEBS_PROJECT_PATH="$(pwd)"
#        export UEBS_SCRIPT_PATH="$(pwd)/ue-build-scripts"
#        export UEBS_PROJECT_NAME=$(basename "$UEBS_PROJECT_PATH")
#        export UEBS_ENGINE_VERSION="12.7"
#        export UEBS_DESIRED_VS_VERSION="2077"
#        export UEBS_DESIRED_DOT_NOT_VERSION=18
#        export UEBS_GIT_LFS_COMMAND="git lfs"
#        export UEBS_LOG_BRANCH_NAME="our_engine_logs"
#
# @NOTE: Linux users must provide the path to their UE5 installation in a variable called 'UE_PATH_LINUX'
#        Add 'export UE_PATH_LINUX="/my/path/to/UE"' to your '.bashrc' or '.zshrc'.
######################################################################################################

# @NOTE: Change this to match your game's root directory.
#        In this case, the script repository is located directly inside
#        of the game's root directory.
default_project_path="$(cd .. && pwd)"
UEBS_PROJECT_PATH="${UEBS_PROJECT_PATH:-$default_project_path}"

# @NOTE: The path to "ue-build-scripts". This depends on how you set up the repo. Make sure this is a full path and 
#        not just relative.
default_scripts_path="$(pwd)"
UEBS_SCRIPTS_PATH="${UEBS_SCRIPTS_PATH:-$default_scripts_path}"

# @NOTE: The path to your Unreal Engine project's root directory. Make sure this a full path and not just relative.
default_project_name=$(basename "$UEBS_PROJECT_PATH")
UEBS_PROJECT_NAME="${UEBS_PROJECT_NAME:-$default_project_name}"

# @NOTE: Your desired Unreal Engine version. Omit patch version: 5.4 and not ~~5.4.1~~.
default_engine_version="5.4"
UEBS_ENGINE_VERSION="${UEBS_ENGINE_VERSION:-$default_engine_version}"

# @NOTE: Your desired minimum Visual Studio product line version
default_desired_vs_version="2022"
UEBS_DESIRED_VS_VERSION="${UEBS_DESIRED_VS_VERSION:-$default_desired_vs_version}"

# @NOTE: The minimum DotNet major version required by UE5
default_desired_dot_net_version=6
UEBS_DESIRED_DOT_NET_VERSION="${UEBS_DESIRED_DOT_NET_VERSION:-$default_desired_dot_net_version}"

# @NOTE: See 'GenerateBugReport.sh'. Set this variable there instead.
default_log_branch_name="junk/logs"
UEBS_LOG_BRANCH_NAME="${UEBS_LOG_BRANCH_NAME:-$default_log_branch_name}"

# @NOTE: Overwrite this variable after sourcing the library script to specify a different git-lfs executable.
#        For example, I am using the UEGitPlugin's custom git-lfs that can lock and unlock files in parallel.
default_git_lfs_command="git lfs"
UEBS_GIT_LFS_COMMAND="${UEBS_GIT_LFS_COMMAND:-$default_git_lfs_command}"

default_git_hooks_path=".git/hooks"
UEBS_GIT_HOOKS_PATH="${UEBS_GIT_HOOKS_PATH:-$default_git_hooks_path}"

######################################################################################################
###################################### Implementations ###############################################
######################################################################################################

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
                UEBS_GIT_LFS_COMMAND="Plugins/UEGitPlugin/git-lfs.exe"
                printSuccess "Found custom LFS executable (Windows)"
            fi
        elif [ "$platform" = "Linux" ]; then
            if [ -f "Plugins/UEGitPlugin/git-lfs" ]; then
                UEBS_GIT_LFS_COMMAND="Plugins/UEGitPlugin/git-lfs"
                printSuccess "Found custom LFS executable (Linux)"
            fi
        fi
    fi
}

verifyVisualStudioVersion() {
    vs_version="$(./ThirdParty/vswhere.exe -property catalog_productLineVersion -prerelease)"
    if [ $? -ne 0 ]; then
        throwError "Failed to run vswhere.exe. Check if it exists in the same directory as 'Library.sh'"
    fi

    if ! [[ "$vs_version" = *"$UEBS_DESIRED_VS_VERSION"* ]]; then
        throwError "Please install Visual Studio Community 2022 and try again."
    fi
}

verifyDotNetVersion() {
    if ! [ -x "$(command -v dotnet)" ]; then
        throwError "Please install DotNet $UEBS_DESIRED_DOT_NET_VERSION.x.x or higher and try again."
    else
        # @TODO: String to int comparisons should be simpler than this!
        dot_net_version="$(dotnet --version)"
        dot_net_version=${dot_net_version%.*}
        dot_net_version=${dot_net_version%.*}
        if [ $dot_net_version -lt $UEBS_DESIRED_DOT_NET_VERSION ]; then
            throwError "Please update your DotNet installation to version $UEBS_DESIRED_DOT_NET_VERSION.x.x or higher and try again."
        fi
    fi
}

checkDependencies() {
    printHeader "Checking dependencies ..."

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

update() {
    printHeader "Updating repository ..."
}

prepare() {
    printHeader "Preparing repository ..."

    cd "$UEBS_PROJECT_PATH"
    
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
    git config core.hooksPath "$UEBS_GIT_HOOKS_PATH"
    if [ $? -ne 0 ]; then
        throwError "Failed to set git hooks path. Please try updating your git installation."
    fi
    
    # Make sure hooks are available
    # @TODO: This overwrites any custom hooks
    git lfs update --force

    # Load Git aliases
    git config include.path "../.gitalias"

    # Checkout all submodules
    # git submodule update --init --recursive
    # if [ $? -ne 0 ]; then
    #     throwError "Failed to update submodules. Please ask tech for help."
    # fi
    
    cd -

    echo
}

fetch() {
    printHeader "Fetching project information ..."
    
    # @TODO: Consider parsing .uproject file to extract engine version

    # Determine where UE is installed on this machine (Windows only)
    # Linux
    if [ "$platform" = "Linux" ]; then
        engine_path="$UE_PATH_LINUX"
        if [ -z "$engine_path" ]; then
            throwError "Please set the path to your UE5 installation in a variable called UE_PATH_LINUX. Add 'export UE_PATH_LINUX=/path/to/my/ue' in your '.bashrc' or '.zshrc' and reload your environment."
        fi

    # Windows
    elif [ "$platform" = "Win64" ]; then
        # Use registry to find install location
        engine_path="$(powershell -command "(Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\\$UEBS_ENGINE_VERSION' -Name 'InstalledDirectory' ).'InstalledDirectory'")"
        engine_path="${engine_path//\\//}"
    else
        throwError "This platform is not supported."
    fi

    if [ -z "$engine_path" ]; then
        throwError "Please install Unreal Engine. If you have already installed it, please ask tech for help."
    fi

    if [ "$platform" = "Win64" ]; then
        editor_path="$engine_path/Engine/Binaries/Win64/UnrealEditor.exe"
        ubt_path="$engine_path/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe"
    elif [ "$platform" = "Linux" ]; then
        editor_path="$engine_path/Engine/Binaries/Linux/UnrealEditor"
        ubt_path="$engine_path/Engine/Build/BatchFiles/Linux/Build.sh"
    fi

    echo "Engine path:    $engine_path"
    echo "Editor path:    $editor_path"
    echo "UBT path:       $ubt_path"
    echo "Project path:   $UEBS_PROJECT_PATH"
    echo "Project name:   $UEBS_PROJECT_NAME"

    echo
}

build() {
    if [ -z "$platform" ]; then
        throwError "This platform is not supported."
    fi

    if [ -d "$UEBS_PROJECT_PATH/Source" ]; then
        if ! [[ -d "$UEBS_PROJECT_PATH/Binaries" ]] || ! [[ -d "$UEBS_PROJECT_PATH/Intermediate" ]]; then
            printHeader "Generating project files ..."

            "$ubt_path" -projectFiles -Project="$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -game -rocket -progress

            if [ $? -ne 0 ]; then
                throwError "Failed to generate project files ..."
            fi

            echo
        fi

        printHeader "Compiling C++ ..."

        "$ubt_path" Development "$platform" -Project="$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE

        if [ $? -ne 0 ]; then
            echo
            printError "Failed to compile $UEBS_PROJECT_NAME." 
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
    printHeader "Launching $UEBS_PROJECT_NAME ..."
    echo "The editor might launch silently, so please give it a few minutes."

    if [ "$platform" = "Win64" ]; then
        "$editor_path" "$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" &
    elif [ "$platform" = "Linux" ]; then
        "$editor_path" "$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" &
    else
        throwError "This platform is not supported."
    fi

    if [ $? -ne 0 ]; then
        throwError "Failed to launch UnrealEditor."
    fi
}

uploadEngineLogs() {
    printHeader "Uploading engine log"

    cd "$UEBS_PROJECT_PATH"
    git ls-remote --exit-code --heads origin "$UEBS_LOG_BRANCH_NAME"
    if [ $? -ne 0 ]; then
        throwError "Failed to upload engine log: The branch $UEBS_LOG_BRANCH_NAME does not exist on the remote. Please create it first and try again."
    fi

    log_file="${UEBS_PROJECT_PATH}/Saved/Logs/${UEBS_PROJECT_NAME}.log"

    if ! [[ -f "$log_file" ]]; then
        throwError "No engine log has been created yet."
    fi

    # Retrieve GitHub url of game repo
    remote_url=$(git remote get-url origin)
    echo "HERE: $remote_url"

    cd - 1> /dev/null

    # Assign a slightly unusual directory name to avoid conflicts and accidental deletion
    staging_dir="${UEBS_PROJECT_NAME}_logs_staging"

    # Clone single orphan branch called ${UEBS_LOG_BRANCH_NAME}
    git clone --single-branch --branch "$UEBS_LOG_BRANCH_NAME" "$remote_url" "$staging_dir"
    # @TODO: This check is always false 
    # if [ $? -ne 0 ]; then
    #     throwError "Failed to clone orphan branch $UEBS_LOG_BRANCH_NAME"
    # fi

    # Retrieve current time
    local_time=$(date)

    # Retrieve Git user name
    git_user_name=$(git config user.name)

    # Create the target directory for copying
    mkdir -p "${staging_dir}/Logs"

    # Copy the log file
    cp "$log_file" "${staging_dir}/Logs/${git_user_name}_${local_time}"

    # Enter the directory of the orphan branch
    cd "$staging_dir"

    # Make sure the local orphan branch is up to date
    git pull --rebase

    # Stage, commit, and push the log file
    git add --all
    git commit -m "Upload engine log"
    git push

    # Keep track of that commit
    log_commit_info="$(git log -1 --oneline) 
$(git config --get remote.origin.url | sed -e 's/\.git$//g')/commit/$(git rev-parse HEAD)"

    # Go back to the previous directory
    cd -

    # Delete the local folder of the orphan branch
    rm -rf "$staging_dir"

    echo
}

# @NOTE: Requires uploadEngineLogs to be run before executing this function
generateBugReport () {
    printHeader "Generating bug report and copying to clipboard ..."

    cd ..
    commit_info="$(git log -1 --oneline)
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
${commit_info}

### Logs:
${log_commit_info}"

    copyToClipboard "$output"

}

cleanBuildFiles() {
    printHeader "Cleaning $UEBS_PROJECT_NAME build files ..."

    rm -rf "$UEBS_PROJECT_PATH/Binaries" "$UEBS_PROJECT_PATH/Intermediate" "$UEBS_PROJECT_PATH/*.sln"

    printWarning "Now you may run 'Launch.sh' again."
    echo 
}

unlockAll() {
    if [ $# -ne 1 ]; then
        echo "Please provide your project root directory as an argument."
        exit
    fi

    read -p "This function will delete all uncommitted local changes. Are you sure that you want to proceed? [yN] (enter y to confirm) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi

    cd "$1"

    locks=$(echo "$($UEBS_GIT_LFS_COMMAND locks | grep -i $(git config user.name))" | awk '{print $1}')
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
    $UEBS_GIT_LFS_COMMAND unlock $(echo $locks)
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
    tmp_dir=$(mktemp -dp "${TMPDIR:-/tmp}" "${prefix}.XXXXX")
    trap "rm -rf -- '${tmp_dir}'" EXIT

    args=
    [[ $# -ge 1 ]] && args=$(printf ' %q' "$@")

    if [[ -t 0 ]]; then
        winpty </dev/tty >/dev/tty -- bash -c \
            "command $fzf${args} >'${tmp_dir}'/output"
        cat "${tmp_dir}"/output
    else
        cat - >"${tmp_dir}"/input
        winpty </dev/tty >/dev/tty -- bash -c \
            "command $fzf${args} <'${tmp_dir}'/input >'${tmp_dir}'/output"
        cat "${tmp_dir}"/output
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
        UEBS_GIT_LFS_COMMAND="${UEBS_GIT_LFS_COMMAND} lock"

        fetchFzfCmd

        # Get all uassets in Content directory
        selected_files="$(find Content/ -name '*.uasset' | awk '{print $1}' | "$fzf_cmd" --multi)"
        if [[ -n "$selected_files" ]]; then
            # Switch end of lines with white spaces
            selected_files=$(echo "$selected_files" | tr -s '\n' ' ')

            eval "$UEBS_GIT_LFS_COMMAND" "$selected_files"
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

    eval "$UEBS_GIT_LFS_COMMAND" lock "$files_to_lock"
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
    UEBS_GIT_LFS_COMMAND="${UEBS_GIT_LFS_COMMAND} unlock"

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
                UEBS_GIT_LFS_COMMAND="${UEBS_GIT_LFS_COMMAND} --force"
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
        locks="$($UEBS_GIT_LFS_COMMAND locks | grep -i $(git config user.name) | awk '{print $1}')"

        # Do not need to proceed if no locks exist
        if [[ -z "$locks" ]]; then
            echo "Nothing to do"
            exit
        fi

        # Switch end of lines with white spaces
        locks=$(echo "$locks" | tr -s '\n' ' ')

        # Perform unlocking
        eval "$UEBS_GIT_LFS_COMMAND" "$locks"
        exit
    fi

    # Handle no input (launch fzf to allow for unlocking)
    if [[ -z "$input" ]]; then
        fetchFzfCmd

        # Get the users locked files via fzf
        selected_files="$($UEBS_GIT_LFS_COMMAND locks | grep -i $(git config user.name) | awk '{print $1}' | "$fzf_cmd" --multi)"
        if [[ -n "$selected_files" ]]; then
            # Switch end of lines with white spaces
            selected_files=$(echo "$selected_files" | tr -s '\n' ' ')

            eval "$UEBS_GIT_LFS_COMMAND" "$selected_files"
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
    eval "$UEBS_GIT_LFS_COMMAND" "$files_to_unlock"
}
