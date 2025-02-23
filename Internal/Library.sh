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
#        export UEBS_GIT_LFS_EXECUTABLE="git lfs"
#        export UEBS_LOG_BRANCH_NAME="our_engine_logs"
#        export UEBS_PACKAGE_ARGS="-configuration=Shipping -nocompileeditor -unattended -utf8output -build -cook"
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

# If specified, use this engine path instead
UEBS_ENGINE_PATH_OVERRIDE=""

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
default_git_lfs_executable="git lfs"
UEBS_GIT_LFS_EXECUTABLE="${UEBS_GIT_LFS_EXECUTABLE:-$default_git_lfs_executable}"

# @NOTE: You may want to specify
default_git_hooks_path=".git/hooks"
UEBS_GIT_HOOKS_PATH="${UEBS_GIT_HOOKS_PATH:-$default_git_hooks_path}"

# @NOTE: The branch we consider the latest development version. This is the branch used for rebasing in the
#        auto-update step.
default_project_branch="main"
UEBS_DEFAULT_PROJECT_BRANCH="${UEBS_DEFAULT_PROJECT_BRANCH:-$default_project_branch}"

# @NOTE: The default arguments to use for packaging. There are additional arguments that cannot be skipped, check
# uebs::package for reference. No -clean by default is used.
default_package_args="-configuration=Shipping -nocompileeditor -unattended -utf8output -build -cook -stage -pak -prereqs"
UEBS_PACKAGE_ARGS="${UEBS_PACKAGE_ARGS:-$default_package_args}"

######################################################################################################
###################################### Implementations ###############################################
######################################################################################################

uebs::get_platform() {
    if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        platform="Linux"
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        platform="Win64"
    elif [ "$(expr substr $(uname -s) 1 10)" == "MSYS_NT-10" ]; then
        platform="Win64"
    else
        uebs::throw_error "This platform is not supported."
    fi
}

uebs::copy_to_clipboard() {
    uebs::get_platform

    if [ "$platform" = "Win64" ]; then
        echo "$1" | clip
    elif [ "$platform" = "Linux" ]; then
        echo "$1" | xclip -selection c
    fi
}

uebs::wait_for_input() {
    read -p "Press ENTER to continue ..."
}

uebs::print_error() {
    echo -e "\e[31m$1\e[0m"
}

uebs::print_warning() {
    echo -e "\e[33m$1\e[0m"
}

uebs::print_success() {
    echo -e "\e[32m$1\e[0m"
}

uebs::print_header() {
    banner="=========================================="
    echo -e "\e[33m${banner}\n$1\n${banner}\e[0m\n"
}

uebs::throw_error() {
    echo
    uebs::print_error "$1"
    echo

    uebs::wait_for_input
    exit 1
}

# @TODO: Add compiler version check?
uebs::verify_vs_version() {
    vs_version="$(./ThirdParty/vswhere.exe -property catalog_productLineVersion -prerelease)"
    if [ $? -ne 0 ]; then
        uebs::throw_error "Failed to run vswhere.exe. Check if it exists in the same directory as 'Library.sh'"
    fi

    if ! [[ "$vs_version" = *"$UEBS_DESIRED_VS_VERSION"* ]]; then
        uebs::throw_error "Please install Visual Studio Community 2022 and try again."
    fi
}

uebs::verify_dot_net_version() {
    if ! [ -x "$(command -v dotnet)" ]; then
        uebs::throw_error "Please install DotNet $UEBS_DESIRED_DOT_NET_VERSION.x.x or higher and try again."
    else
        # @TODO: String to int comparisons should be simpler than this!
        dot_net_version="$(dotnet --version)"
        dot_net_version=${dot_net_version%.*}
        dot_net_version=${dot_net_version%.*}
        if [ $dot_net_version -lt $UEBS_DESIRED_DOT_NET_VERSION ]; then
            uebs::throw_error "Please update your DotNet installation to version $UEBS_DESIRED_DOT_NET_VERSION.x.x or higher and try again."
        fi
    fi
}

uebs::check_dependencies() {
    uebs::print_header "Checking dependencies ..."

    # Git
    if ! [ -x "$(command -v git)" ]; then
        uebs::throw_error "Please install Git and try again."
    fi

    # Git-LFS
    if ! [ -x "$(command -v git-lfs)" ]; then
        uebs::throw_error "Please install Git-LFS 2 and try again."
    fi

    uebs::get_platform

    # Check if VS 2022 is installed (Windows only)
    if [ "$platform" = "Win64" ]; then
        uebs::verify_vs_version

        # Check if DotNet 6.x.x or higher is installed
        uebs::verify_dot_net_version
    fi

    echo
}

uebs::update() {
    uebs::print_header "Updating repository ..."

    cd "$UEBS_PROJECT_PATH"

    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    echo "Current branch: $current_branch"
    echo "Default branch: $UEBS_DEFAULT_PROJECT_BRANCH"

    if [[ "$current_branch" == "$UEBS_DEFAULT_PROJECT_BRANCH" ]]; then
        echo "Current branch is project default branch. Skipping auto-update ..."
    else
        echo "Updating $UEBS_DEFAULT_PROJECT_BRANCH ..."

        # Update project branch without switching to it
        git fetch origin $UEBS_DEFAULT_PROJECT_BRANCH:$UEBS_DEFAULT_PROJECT_BRANCH
        if [ $? -ne 0 ]; then
            uebs::throw_error "Failed to update project branch '$UEBS_DEFAULT_PROJECT_BRANCH'."
        fi

        # Verify that the default project branch has not diverged from the origin after merging
        diff_to_origin="$(git diff $UEBS_DEFAULT_PROJECT_BRANCH origin/$UEBS_DEFAULT_PROJECT_BRANCH)"
        if [ -n "$diff_to_origin" ]; then
            uebs::throw_error "Failed to update project branch '$UEBS_DEFAULT_PROJECT_BRANCH'. Your local branch has diverged. Please discard or merge your local commits."
        fi

        # Check if project branch is ahead of current branch
        if [[ $(git rev-list --count $current_branch..$UEBS_DEFAULT_PROJECT_BRANCH) -gt 0 ]]; then
            # Ask user if they really want to update their branch
            echo
            uebs::print_warning "There are updates on $UEBS_DEFAULT_PROJECT_BRANCH: "

            # Display all changes
            change_log="$(git log --oneline --pretty=format:"%an: %s" $current_branch..$UEBS_DEFAULT_PROJECT_BRANCH)"
            if [ -n "$change_log" ]; then
                echo
                echo "$change_log"
                echo
            fi

            uebs::print_warning "Would you like to update your branch? This will force-push the remote branch, if available. [y/N] "
            read -p "Press 'y' to update, or 'n' to skip. " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo
                echo "Updating branch ..."
                echo

                has_stashed=0

                # If there are any local changes (modified files) we need to stash them first
                local_changes="$(git status --porcelain --untracked-files=no)"
                if [ -n "$local_changes" ]; then
                    has_stashed=1

                    git stash
                    if [ $? -ne 0 ]; then
                        uebs::throw_error "Failed to stash local changes. Ask tech for help."
                    fi
                fi

                git rebase $UEBS_DEFAULT_PROJECT_BRANCH $current_branch
                if [ $? -ne 0 ]; then
                    git rebase --abort

                    # If we stashed we need to apply stash again
                    if [ "$has_stashed" -eq 1 ]; then
                        git stash apply
                        if [ $? -ne 0 ]; then
                            uebs::throw_error "Failed to apply stash after rebase failed. Ask tech for help before proceeding with work."
                        fi
                    fi

                    uebs::throw_error "Failed to update local branch. Try updating manually or ask tech for help."
                fi

                # Re-apply stash
                if [ "$has_stashed" -eq 1 ]; then
                    git stash apply
                    if [ $? -ne 0 ]; then
                        uebs::throw_error "Failed to apply stash. Ask tech for help before proceeding with work."
                    fi
                fi

                uebs::print_success "Successfully updated local branch."

                # If there is no remote branch, there is no need to force-push
                git show-branch remotes/origin/$current_branch >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    echo "Current branch has no remote. Skipping force push ..."
                else
                    git push --force-with-lease
                    if [ $? -ne 0 ]; then
                        uebs::throw_error "Failed to force push current branch. Ask tech for help."
                    fi
                fi
            fi
        else
            echo "Current branch '$current_branch' is up to date with '$UEBS_DEFAULT_PROJECT_BRANCH'"
        fi
    fi

    cd - 1>/dev/null

    echo
}

uebs::prepare() {
    uebs::print_header "Preparing repository ..."

    cd "$UEBS_PROJECT_PATH"

    # Load custom git hooks
    git config core.hooksPath "$UEBS_GIT_HOOKS_PATH"
    if [ $? -ne 0 ]; then
        uebs::throw_error "Failed to set git hooks path. Please try updating your git installation."
    fi

    # @note Only install LFS if no custom Git hooks path is specified.
    # We assume that if it was specified, the user has custom Git hooks that they don't wish to be overwritten
    if [[ "$UEBS_GIT_HOOKS_PATH" == "$default_git_hooks_path" ]]; then
        # Initialize LFS
        git lfs install --force
        if [ $? -ne 0 ]; then
            uebs::throw_error "Failed to initialize Git LFS. Please ask tech for help."
        fi
    fi

    # Set rebase policy
    git config pull.rebase true

    # LF (Unix, Mac) - CRLF (Windows) policy
    # @NOTE: Please use .gitattributes in your repo instead
    git config core.autocrlf true

    # Make sure hooks are available
    if [[ "$UEBS_GIT_HOOKS_PATH" == "$default_git_hooks_path" ]]; then
        git lfs update --force
    fi

    # Load Git aliases
    git config include.path "../.gitalias"

    # Checkout all submodules
    git submodule update --init --recursive
    if [ $? -ne 0 ]; then
        uebs::throw_error "Failed to update submodules. Please ask tech for help."
    fi

    cd - 1>/dev/null

    echo
}

uebs::fetch() {
    uebs::print_header "Fetching project information ..."

    # @TODO: Consider parsing .uproject file to extract engine version

    # Determine where UE is installed on this machine (Windows only)
    # Linux
    if [ "$platform" = "Linux" ]; then
        engine_path="$UE_PATH_LINUX"
        if [ -z "$engine_path" ]; then
            uebs::throw_error "Please set the path to your UE5 installation in a variable called UE_PATH_LINUX. Add 'export UE_PATH_LINUX=/path/to/my/ue' in your '.bashrc' or '.zshrc' and reload your environment."
        fi

    # Windows
    elif [ "$platform" = "Win64" ]; then
        # Use registry to find install location

        if [ -z "$UEBS_ENGINE_PATH_OVERRIDE" ]; then
            engine_path="$(powershell -command "(Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\\$UEBS_ENGINE_VERSION' -Name 'InstalledDirectory' ).'InstalledDirectory'")"
            engine_path="${engine_path//\\//}"
        else
            engine_path="$UEBS_ENGINE_PATH_OVERRIDE"
            engine_path="${engine_path//\\//}"
        fi

    else
        uebs::throw_error "This platform is not supported."
    fi

    if [ -z "$engine_path" ]; then
        uebs::throw_error "Please install Unreal Engine. If you have already installed it, please ask tech for help."
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

uebs::build() {
    if [ -z "$platform" ]; then
        uebs::throw_error "This platform is not supported."
    fi

    if [ -d "$UEBS_PROJECT_PATH/Source" ]; then
        if ! [[ -d "$UEBS_PROJECT_PATH/Binaries" ]] || ! [[ -d "$UEBS_PROJECT_PATH/Intermediate" ]]; then
            uebs::print_header "Generating project files ..."

            "$ubt_path" -projectFiles -Project="$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -game -rocket -progress

            if [ $? -ne 0 ]; then
                uebs::throw_error "Failed to generate project files ..."
            fi

            echo
        fi

        uebs::print_header "Compiling C++ ..."

        "$ubt_path" Development "$platform" -Project="$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -TargetType=Editor -Progress -NoEngineChanges -NoHotReloadFromIDE

        if [ $? -ne 0 ]; then
            echo
            uebs::print_error "Failed to compile $UEBS_PROJECT_NAME."
            echo

            read -p "Do you want to upload your engine log? Press 'y' to confirm or any other key to cancel. " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                uebs::upload_engine_logs
                exit 1
            else
                exit 1
            fi
        fi
    fi

    echo
}

uebs::run() {
    uebs::print_header "Launching $UEBS_PROJECT_NAME ..."
    echo "The editor might launch silently, so please give it a few minutes."

    if [ "$platform" = "Win64" ]; then
        "$editor_path" "$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" &
    elif [ "$platform" = "Linux" ]; then
        "$editor_path" "$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" &
    else
        uebs::throw_error "This platform is not supported."
    fi

    if [ $? -ne 0 ]; then
        uebs::throw_error "Failed to launch UnrealEditor."
    fi
}

# You may pass additional package args as arguments to this function but prefer setting UEBS_PACKAGE_ARGS instead
uebs::package() {
    uebs::print_header "Packaging $UEBS_PROJECT_NAME ..."

    uebs::get_platform
    uebs::fetch

    current_date="$(date +"%y.%m.%d-%H.%M")"
    output_path="${UEBS_PROJECT_PATH}/Builds"
    output_directory_name="${UEBS_PROJECT_NAME}-${current_date}-${platform}"

    # If the build includes debug files, change the directory name to reflect it
    default_game_config="$UEBS_PROJECT_PATH/Config/DefaultGame.ini"
    if [ -e "$default_game_config" ]; then
        if grep -qE 'IncludeDebugFiles\s*=\s*True' "$default_game_config"; then
            uebs::print_error "⛔ This build contains debug files and must NOT be distributed. Use for internal testing only."
            echo

            sleep 2
            output_directory_name="${output_directory_name}-InternalOnly"
        fi
    fi
    
    # Start packaging
    output_dir="${output_path}/${output_directory_name}"
    "${engine_path}/Engine/Build/BatchFiles/RunUAT.bat" BuildCookRun -project="$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -platform=$platform $UEBS_PACKAGE_ARGS -package -archive -archivedirectory="$output_dir" "$@"
    if [ $? -ne 0 ]; then
        uebs::print_error "Packaging failed."
        exit 1
    else
        echo "Packaging completed. You may start testing now."
        
        # Create a build description
        commit_hash="$(git --git-dir="${UEBS_PROJECT_PATH}/.git" --work-tree="$UEBS_PROJECT_PATH" rev-parse --short HEAD)"
        {
            echo "# ${UEBS_PROJECT_NAME}"
            echo "## Build Specifications"
            echo ""
            echo "Date: $current_date<br>"
            echo "Commit: $commit_hash<br>"
            echo "Platform: $platform<br>"
        } > "$output_dir/Windows/README.md"
        
        mv "$output_dir/Windows" "$output_dir/${output_directory_name}/"
    fi

    # Create compressed archive of the output
    if [ -d "$output_dir" ]; then
        echo
        uebs::print_header "Creating compressed archive ..."
        
        if [ "$platform" = "Win64" ]; then
            output_dir_win="$(cygpath -w "$output_dir")"
            powershell Compress-Archive "$output_dir_win\\${output_directory_name}" "${output_dir_win}\\${output_directory_name}.zip"
            echo "Compression finished"
            echo "You will find the archive in \"$output_dir_win/\"."
            
            explorer "$output_dir_win"
            
        elif [ "$platform" = "Linux" ]; then
            uebs::print_error "Compression of packaging output not yet implemented on Linux."
        fi
        
    fi
    
    echo
    uebs::print_success "Packaging finished."
}

uebs::upload_engine_logs() {
    uebs::print_header "Uploading engine log"

    cd "$UEBS_PROJECT_PATH"
    git ls-remote --exit-code --heads origin "$UEBS_LOG_BRANCH_NAME"
    if [ $? -ne 0 ]; then
        uebs::throw_error "Failed to upload engine log: The branch $UEBS_LOG_BRANCH_NAME does not exist on the remote. Please create it first and try again."
    fi

    log_file="${UEBS_PROJECT_PATH}/Saved/Logs/${UEBS_PROJECT_NAME}.log"

    if ! [[ -f "$log_file" ]]; then
        uebs::throw_error "No engine log has been created yet."
    fi

    # Retrieve GitHub url of game repo
    remote_url=$(git remote get-url origin)
    echo "HERE: $remote_url"

    cd - 1>/dev/null

    # Assign a slightly unusual directory name to avoid conflicts and accidental deletion
    staging_dir="${UEBS_PROJECT_NAME}_logs_staging"

    # Clone single orphan branch called ${UEBS_LOG_BRANCH_NAME}
    git clone --single-branch --branch "$UEBS_LOG_BRANCH_NAME" "$remote_url" "$staging_dir"
    # @TODO: This check is always false
    # if [ $? -ne 0 ]; then
    #     uebs::throw_error "Failed to clone orphan branch $UEBS_LOG_BRANCH_NAME"
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
    cd - 1>/dev/null

    # Delete the local folder of the orphan branch
    rm -rf "$staging_dir"

    echo
}

# @NOTE: Requires uebs::upload_engine_logs to be run before executing this function
uebs::generate_bug_report() {
    uebs::print_header "Generating bug report and copying to clipboard ..."

    cd ..
    commit_info="$(git log -1 --oneline)
$(git config --get remote.origin.url | sed -e 's/\.git$//g')/commit/$(git rev-parse HEAD)"
    cd - 1>/dev/null

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

    uebs::copy_to_clipboard "$output"

}

uebs::clean_build_files() {
    uebs::print_header "Cleaning $UEBS_PROJECT_NAME build files ..."

    rm -rf "$UEBS_PROJECT_PATH/Binaries" "$UEBS_PROJECT_PATH/Intermediate" "$UEBS_PROJECT_PATH/*.sln"

    uebs::print_warning "Now you may run 'Launch.sh' again."
    echo
}

# In Git bash for windows, pipes and fzf do not work. This is a workaround from https://github.com/junegunn/fzf/issues/2798#issuecomment-1229376159
uebs::fzf_win_wrapper() {
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

uebs::fetch_fzf_command() {
    uebs::get_platform

    if [ "$platform" = "Win64" ]; then
        fzf_cmd="uebs::fzf_win_wrapper"

    elif [ "$platform" = "Linux" ]; then
        fzf_cmd="Scripts/ThirdParty/fzf"
    fi
}

# @TODO: Remove because user should specify it via export
uebs::run_git_lfs_command() {
    uebs::get_platform

    git_lfs_executable="$UEBS_GIT_LFS_EXECUTABLE"

    # Only check default paths if no custom lfs executable was specified
    if [ "$default_git_lfs_executable" == "$UEBS_GIT_LFS_EXECUTABLE" ]; then
        if [ -d "Plugins/UEGitPlugin" ]; then
            if [ "$platform" = "Win64" ]; then
                if [ -f "Plugins/UEGitPlugin/git-lfs.exe" ]; then
                    uebs::print_success "Found custom LFS executable (Windows)"
                    git_lfs_executable="Plugins/UEGitPlugin/git-lfs.exe"
                fi
            elif [ "$platform" = "Linux" ]; then
                if [ -f "Plugins/UEGitPlugin/git-lfs" ]; then
                    uebs::print_success "Found custom LFS executable (Linux)"
                    git_lfs_executable="Plugins/UEGitPlugin/git-lfs"
                fi
            fi
        fi
    fi

    eval "${git_lfs_executable}" "$@"
}

uebs::lock() {
    uebs::fetch_fzf_command

    # Get all .uassets in content directory
    selected_files="$(find Content/ -name '*.uasset' | awk '{print $1}' | "$fzf_cmd" --multi)"
    if [[ -n "$selected_files" ]]; then
        # Switch end of lines with white spaces
        selected_files=$(echo "$selected_files" | tr -s '\n' ' ')

        uebs::run_git_lfs_command "lock" "$selected_files"
        uebs::copy_to_clipboard "$selected_files"
    fi
}

uebs::unlock() {
    uebs::fetch_fzf_command

    # Get the users locked files via fzf
    selected_files="$($UEBS_GIT_LFS_EXECUTABLE locks | grep -i "$(git config user.name)" | awk '{print $1}' | "$fzf_cmd" --multi)"
    if [[ -n "$selected_files" ]]; then
        # Switch end of lines with white spaces
        selected_files=$(echo "$selected_files" | tr -s '\n' ' ')

        uebs::run_git_lfs_command "unlock" "$selected_files"
        uebs::copy_to_clipboard "$selected_files"
    fi
}

uebs::unlock_all() {
    if [ $# -ne 1 ]; then
        echo "Please provide your project root directory as an argument."
        exit
    fi

    read -p "This function will delete all uncommitted local changes. Are you sure that you want to proceed? [y/N] (enter y to confirm) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi

    cd "$1"

    locks=$(echo "$($UEBS_GIT_LFS_EXECUTABLE locks | grep -i $(git config user.name))" | awk '{print $1}')
    if [ -z "$locks" ]; then
        echo "Nothing to do"
        exit
    fi

    echo "$locks" | while read line; do
        mkdir -p "$(dirname "$line")"
        touch $line
        git add $line -f
    done

    git commit -m "Remove locks"
    uebs::run_git_lfs_command "unlock" "$(echo $locks)"
    git reset --hard HEAD~1

    uebs::copy_to_clipboard "$locks"

    cd - 1>/dev/null
}
