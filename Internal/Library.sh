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
#
# @NOTE: Linux users must provide the path to their UE5 installation in a variable called 'UE_PATH_LINUX'
#        Add 'export UE_PATH_LINUX="/my/path/to/UE"' to your '.bashrc' or '.zshrc'.

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
default_engine_path_override=""
UEBS_ENGINE_PATH_OVERRIDE="${UEBS_ENGINE_PATH_OVERRIDE:-$default_engine_path_override}"

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

# @NOTE: Set this to your full Wwise version string (e.g. "2025.1.6.9117") to enable automatic soundbank
#        generation before packaging. Soundbank generation is Windows-only and silently skipped otherwise.
default_wwise_version=""
UEBS_WWISE_VERSION="${UEBS_WWISE_VERSION:-$default_wwise_version}"

# @NOTE: The directory to put the rclone executable
default_tools_dir="${UEBS_PROJECT_PATH}/.tools"
UEBS_TOOLS_DIR="${UEBS_TOOLS_DIR:-$default_tools_dir}"

# @NOTE: The default rclone version to use to get dependencies from common cloud storage providers
default_rclone_version="v1.68.2"
UEBS_RCLONE_VERSION="${UEBS_RCLONE_VERSION:-$default_rclone_version}"

# @NOTE: Define external dependencies as newline-separated entries:
#        "remote_name|remote_type|remote_source_path|local_dest_path"
#        Each unique remote is configured on first use (may open a browser for auth).
#        Set this in your Launch.sh. Single entry example:
#        export UEBS_EXTERNAL_DEPENDENCIES="wwise-plugin|drive|SomeFolder/ThirdParty/Wwise-2025.1.6.9117.zip|Plugins"
#        The above line would download the Wwise.zip from your Google drive and extract it to your project's `Plugins` folder.
#        Multiple entries (use $'...' for literal newlines):
#        export UEBS_EXTERNAL_DEPENDENCIES=$'remote-a|drive|SourceA|DestA\nremote-b|s3|SourceB|DestB'
#
#        If an external dependency was set up, a `.dep_versions` file will be created in the project root directory if the
#        dependency was downloaded and extracted successfully. The dependency won't be downloaded again, unless the name of
#        the zip to download has changed.
#        For example in the case of Wwise, I'd store it on your drive with the version encoded like `Wwise-2025.1.6.9117.zip`.
#        This would also allow other devs to check out an older version of the repo (assuming the older dependency wasn't deleted).
#        However, keep in mind that if you previously had the dependency tracked by Git, there will be a conflict trying to switch
#        to the older commit. You would have to delete the downloaded dependencies manually before.
default_external_dependencies=""
UEBS_EXTERNAL_DEPENDENCIES="${UEBS_EXTERNAL_DEPENDENCIES:-$default_external_dependencies}"

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
# Param1: true if build is for distribution
uebs::package() {
    uebs::print_header "Packaging $UEBS_PROJECT_NAME ..."

    uebs::get_platform
    uebs::fetch

    # The cook runs on the editor binaries, so rebuild them in case they are from another branch or commit.
    # Otherwise cooked Blueprints can mismatch the game's C++ and fail to load ("Bad export index").
    uebs::build

    local is_distributable=$1
    local build_flags=""

    current_date="$(date +"%y.%m.%d-%H.%M")"
    output_path="${UEBS_PROJECT_PATH}/Builds"
    output_directory_name="${UEBS_PROJECT_NAME}-${current_date}-${platform}"

    if [ "$is_distributable" = true ]; then
        build_flags+="-nodebuginfo -distribution"
    else
        output_directory_name="InternalOnly-${output_directory_name}"
    fi

    # Start packaging
    output_dir="${output_path}/${output_directory_name}"

    "${engine_path}/Engine/Build/BatchFiles/RunUAT.bat" BuildCookRun -nop4 -utf8output -nocompileeditor -skipbuildeditor -cook -project="$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -target=${UEBS_PROJECT_NAME} -platform=$platform -installed -stage -archive -package -build -pak -iostore -compressed -prereqs -archivedirectory="$output_dir" -CrashReporter -clientconfig=Shipping $build_flags

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
            archive_name="${output_directory_name}.zip"
            seven_zip="$(cygpath -u "$PROGRAMFILES")/7-Zip/7z.exe"
            rm -f "$output_dir/$archive_name"

            # Compress-Archive in Windows PowerShell 5.1 fails on files over 2 GB, so use 7-Zip if installed and
            # otherwise the bsdtar that ships with Windows 10 and later
            if [ -f "$seven_zip" ]; then
                (cd "$output_dir" && "$seven_zip" a -tzip -bso0 -bsp1 "$archive_name" "$output_directory_name")
            else
                (cd "$output_dir" && "$(cygpath -u "$SYSTEMROOT")/System32/tar.exe" -a -c -f "$archive_name" "$output_directory_name")
            fi

            if [ $? -ne 0 ]; then
                uebs::print_error "Compression failed. The uncompressed build is in \"$output_dir_win\"."
                explorer "$output_dir_win"
                exit 1
            fi

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

# Static lighting is baked with the ResavePackages commandlet. Whether a map needs a bake is a guess: after each
# bake, the hashes of the persistent .umap and every .umap it references are stored in
# Saved/BuildLighting/<Map>.stamp. Changes to meshes, materials or lighting settings outside those files are not
# detected.

lighting_quality_levels=(Preview Medium High Production)
lighting_selected_maps=()
lighting_quality=""

# Prints the long package names of the maps in MapsToCook, e.g. /Game/Marmortal/Maps/Menu/MainMenuLevel
uebs::maps_to_cook() {
    grep -h '^+MapsToCook=' "$UEBS_PROJECT_PATH/Config/DefaultGame.ini" | sed -E 's/.*FilePath="([^"]+)".*/\1/'
}

# Param1: a map name like PlayGround or a long package name. Prints the path of its .umap relative to the project.
uebs::map_file() {
    local map="$1"

    if [[ "$map" == /Game/* ]]; then
        echo "Content/${map#/Game/}.umap"
        return
    fi

    (cd "$UEBS_PROJECT_PATH" && find Content -name "${map}.umap" -print -quit)
}

# Param1: the .umap of a persistent level. Prints it and every other .umap it references, such as streaming
# sublevels and level instances. The references are read from the package's name table.
uebs::level_files() {
    local persistent_file="$1"

    echo "$persistent_file"
    grep -a -o '/Game/[A-Za-z0-9_/]*' "$UEBS_PROJECT_PATH/$persistent_file" | sort -u | while read -r package; do
        local file="Content/${package#/Game/}.umap"
        if [ "$file" != "$persistent_file" ] && [ -f "$UEBS_PROJECT_PATH/$file" ]; then
            echo "$file"
        fi
    done
}

# Param1: the .umap of a persistent level. Prints "<sha1>  <file>" for each of its level files.
uebs::lighting_fingerprint() {
    (cd "$UEBS_PROJECT_PATH" && uebs::level_files "$1" | xargs -d '\n' sha1sum)
}

uebs::lighting_stamp_file() {
    echo "$UEBS_PROJECT_PATH/Saved/BuildLighting/$(basename "$1" .umap).stamp"
}

# Param1: the .umap of a persistent level. Prints one line describing whether it changed since its last bake.
# Returns 0 if it looks unchanged.
uebs::lighting_status() {
    local map_file="$1"
    local map_directory
    map_directory="$UEBS_PROJECT_PATH/$(dirname "$map_file")"
    local stamp
    stamp="$(uebs::lighting_stamp_file "$map_file")"

    if [ ! -f "$UEBS_PROJECT_PATH/$map_file" ]; then
        echo "map file not found"
        return 1
    fi

    if [ ! -f "$stamp" ]; then
        echo "no bake recorded on this machine"
        return 1
    fi

    if [ -z "$(find "$map_directory" -maxdepth 1 -name '*_BuiltData.uasset' -print -quit)" ]; then
        echo "no built data on disk"
        return 1
    fi

    local changed
    changed="$(uebs::lighting_fingerprint "$map_file" | diff "$stamp" - | grep '^[<>]' | awk '{print $3}' | sort -u | xargs -r -n1 basename | tr '\n' ' ')"
    if [ -n "$changed" ]; then
        echo "changed since last bake: $changed"
        return 1
    fi

    echo "unchanged since last bake ($(date -r "$stamp" '+%Y-%m-%d %H:%M'))"
    return 0
}

uebs::choose_lighting_quality() {
    local reply

    echo "Lighting quality:"
    for i in "${!lighting_quality_levels[@]}"; do
        echo "  $((i + 1))) ${lighting_quality_levels[$i]}"
    done
    read -r -p "Choose a quality [2) Medium]: " reply
    echo

    case "$reply" in
        "" )
            lighting_quality="Medium"
            ;;
        [1-4] )
            lighting_quality="${lighting_quality_levels[$((reply - 1))]}"
            ;;
        * )
            uebs::print_error "Unknown lighting quality: $reply"
            return 1
            ;;
    esac
}

# Lists the cooked maps with their bake status and stores the user's choice in lighting_selected_maps.
uebs::choose_lighting_maps() {
    local maps=()
    local statuses=()
    local changed=()

    uebs::print_header "Lighting"

    while read -r map; do
        local map_file status
        map_file="$(uebs::map_file "$map")"
        if status="$(uebs::lighting_status "$map_file")"; then
            changed+=(false)
        else
            changed+=(true)
        fi
        maps+=("$(basename "$map")")
        statuses+=("$status")
    done < <(uebs::maps_to_cook)

    echo "Maps in this build (MapsToCook in Config/DefaultGame.ini):"
    for i in "${!maps[@]}"; do
        printf "  %d) %-20s %s\n" "$((i + 1))" "${maps[$i]}" "${statuses[$i]}"
    done
    echo
    uebs::print_warning "These statuses are a guess. They only compare the map's own .umap files with the last bake on this"
    uebs::print_warning "machine, so a bake may not be needed, and changed meshes, materials or lighting settings are missed."
    uebs::print_warning "Baking can take a long time and leaves the baked .umap files modified in your working copy."
    echo

    local reply
    read -r -p "Bake lighting for: [Enter] none, a) all, c) changed only, or numbers/map names separated by spaces: " reply
    echo

    lighting_selected_maps=()
    case "$reply" in
        "" | [Nn] | none)
            echo "Skipping the lighting bake."
            echo
            return 0
            ;;
        [Aa] | all)
            lighting_selected_maps=("${maps[@]}")
            ;;
        [Cc] | changed)
            for i in "${!maps[@]}"; do
                if [ "${changed[$i]}" = true ]; then
                    lighting_selected_maps+=("${maps[$i]}")
                fi
            done
            ;;
        *)
            for item in $reply; do
                if [[ "$item" =~ ^[0-9]+$ ]] && [ "$item" -ge 1 ] && [ "$item" -le ${#maps[@]} ]; then
                    lighting_selected_maps+=("${maps[$((item - 1))]}")
                elif [ -n "$(uebs::map_file "$item")" ]; then
                    lighting_selected_maps+=("$item")
                else
                    uebs::print_error "Unknown map: $item"
                    return 1
                fi
            done
            ;;
    esac

    if [ ${#lighting_selected_maps[@]} -eq 0 ]; then
        echo "No maps selected. Skipping the lighting bake."
        echo
        return 0
    fi

    uebs::choose_lighting_quality || return 1
    echo "Will bake ${lighting_selected_maps[*]} at $lighting_quality quality."
    echo
}

# Params: map names. Bakes them in one commandlet run and records their fingerprints. Returns non-zero on failure.
uebs::build_lighting() {
    local maps=("$@")
    if [ ${#maps[@]} -eq 0 ]; then
        return 0
    fi

    uebs::print_header "Building lighting ($lighting_quality) for: ${maps[*]}"

    if tasklist 2>/dev/null | grep -qi '^UnrealEditor'; then
        uebs::print_error "Unreal Engine is running. Close it so the commandlet doesn't fight over the same files."
        return 1
    fi

    uebs::get_platform
    uebs::fetch
    # The commandlet loads and saves the maps with the editor binaries, so make sure they match the source
    uebs::build
    local editor_cmd="$engine_path/Engine/Binaries/Win64/UnrealEditor-Cmd.exe"

    cd "$UEBS_PROJECT_PATH" || return 1

    local level_files=()
    for map in "${maps[@]}"; do
        local map_file
        map_file="$(uebs::map_file "$map")"
        if [ -z "$map_file" ] || [ ! -f "$map_file" ]; then
            uebs::print_error "Map not found: $map"
            return 1
        fi
        mapfile -t -O "${#level_files[@]}" level_files < <(uebs::level_files "$map_file")
    done

    # Lockable files are read-only until locked, and the commandlet skips read-only maps instead of saving them.
    # Make the level files writable without taking locks. The baked maps are only for this build, so this includes
    # files locked by someone else.
    local me others_locked writable_files=()
    me="$(git config user.name)"
    others_locked="$(git lfs locks 2>/dev/null | awk -v me="$me" '$2 != me {print $1}')"
    for file in "${level_files[@]}"; do
        if [ ! -w "$file" ]; then
            chmod u+w "$file"
            writable_files+=("$file")
        fi
    done

    # The commandlet can't overwrite existing built data ("cannot be saved as it has only been partially loaded"),
    # so move it aside and let the bake create it from scratch
    local backup_directory="$UEBS_PROJECT_PATH/Saved/BuildLighting/BuiltDataBackup"
    rm -rf "$backup_directory"
    for file in "${level_files[@]}"; do
        local built_data="${file%.umap}_BuiltData.uasset"
        if [ -f "$built_data" ]; then
            mkdir -p "$backup_directory/$(dirname "$built_data")"
            mv "$built_data" "$backup_directory/$built_data"
        fi
    done

    local start_marker="$UEBS_PROJECT_PATH/Saved/BuildLighting_start"
    touch "$start_marker"
    local before_hashes
    before_hashes="$(sha1sum "${level_files[@]}")"

    local map_arg log_name start status
    map_arg="$(IFS=+; echo "${maps[*]}")"
    log_name="BuildLighting_$(date +%Y%m%d_%H%M%S).log"
    start=$(date +%s)

    # -nosourcecontrol keeps the commandlet from taking LFS locks through the Git plugin
    "$editor_cmd" "$UEBS_PROJECT_PATH/$UEBS_PROJECT_NAME.uproject" -run=ResavePackages \
        -buildlighting -allowcommandletrendering -quality="$lighting_quality" -map="$map_arg" \
        -nosourcecontrol -unattended -nopause -nosplash -log="$log_name"
    status=$?

    local log_file="$UEBS_PROJECT_PATH/Saved/Logs/$log_name"
    echo
    echo "Commandlet exited with $status after $(( $(date +%s) - start ))s. Log: $log_file"

    # Put the read-only flag back on files the bake didn't change
    for file in "${writable_files[@]}"; do
        if grep -qxF "$(sha1sum "$file")" <<< "$before_hashes"; then
            chmod u-w "$file"
        fi
    done

    # Restore built data the bake didn't recreate, such as for levels without static lighting
    if [ -d "$backup_directory" ]; then
        while read -r built_data; do
            if [ ! -f "$built_data" ]; then
                mv "$backup_directory/$built_data" "$built_data"
            fi
        done < <(cd "$backup_directory" && find Content -type f)
        rm -rf "$backup_directory"
    fi

    echo
    echo "Files the bake saved:"
    find Content -newer "$start_marker" -type f

    local errors failures
    errors="$(grep -E 'Error:' "$log_file" 2>/dev/null)"
    if [ -n "$errors" ]; then
        echo
        uebs::print_warning "Errors from the log (the last 20):"
        tail -20 <<< "$errors"
    fi

    # Other errors, such as broken asset references, don't stop the bake, so only these count as a failure
    failures="$(grep -E 'Failed building lighting|Failed to complete steps|Skipping read-only|Failed to save|Failed to check out' "$log_file" 2>/dev/null)"

    local others_changed=()
    for file in "${level_files[@]}"; do
        if grep -qxF "$file" <<< "$others_locked" && ! grep -qxF "$(sha1sum "$file")" <<< "$before_hashes"; then
            others_changed+=("$file")
        fi
    done
    if [ ${#others_changed[@]} -gt 0 ]; then
        echo
        uebs::print_warning "The bake saved these maps although someone else has them locked. Don't commit them:"
        printf '  %s
' "${others_changed[@]}"
    fi

    if [ $status -ne 0 ] || [ -n "$failures" ]; then
        echo
        uebs::print_error "Lighting bake failed."
        return 1
    fi

    mkdir -p "$UEBS_PROJECT_PATH/Saved/BuildLighting"
    for map in "${maps[@]}"; do
        local map_file
        map_file="$(uebs::map_file "$map")"
        uebs::lighting_fingerprint "$map_file" > "$(uebs::lighting_stamp_file "$map_file")"
    done

    echo
    uebs::print_success "Lighting bake finished."
    echo
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

uebs::generate_wwise_soundbanks() {
    uebs::get_platform

    if [ "$platform" != "Win64" ]; then
        return 0
    fi

    uebs::print_header "Generating Wwise soundbanks ..."

    if [ -z "$UEBS_WWISE_VERSION" ]; then
        uebs::print_warning "UEBS_WWISE_VERSION is not set. Skipping soundbank generation."
        echo
        return 0
    fi

    # Newer Wwise Launcher versions install to "Wwise_<version>", older ones to "Wwise<version>"
    local wwise_console="/c/Audiokinetic/Wwise_${UEBS_WWISE_VERSION}/Authoring/x64/Release/bin/WwiseConsole.exe"

    if [ ! -f "$wwise_console" ]; then
        wwise_console="/c/Audiokinetic/Wwise${UEBS_WWISE_VERSION}/Authoring/x64/Release/bin/WwiseConsole.exe"
    fi

    if [ ! -f "$wwise_console" ]; then
        uebs::print_warning "WwiseConsole.exe not found at: $wwise_console"
        uebs::print_warning "Skipping soundbank generation and continuing with packaging ..."
        echo
        return 0
    fi

    local wproj_path="${UEBS_PROJECT_PATH}/${UEBS_PROJECT_NAME}_WwiseProject/${UEBS_PROJECT_NAME}_WwiseProject.wproj"

    if [ ! -f "$wproj_path" ]; then
        uebs::print_warning "Wwise project file not found at: $wproj_path"
        uebs::print_warning "Skipping soundbank generation and continuing with packaging ..."
        echo
        return 0
    fi

    "$wwise_console" generate-soundbank "$wproj_path" --platform Windows

    if [ $? -ne 0 ]; then
        uebs::print_warning "Soundbank generation failed. Continuing with packaging ..."
    else
        uebs::print_success "Soundbank generation completed."
    fi

    echo
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

uebs::download_dependencies() {
    if [ -z "$UEBS_EXTERNAL_DEPENDENCIES" ]; then
        echo "No external dependencies defined. Skipping."
        return 0
    fi

    uebs::print_header "Downloading external dependencies ..."

    uebs::get_platform

    case "$platform" in
        Linux)
            case "$(uname -m)" in
                x86_64)  OS="linux-amd64" ;;
                aarch64) OS="linux-arm64" ;;
                *) uebs::throw_error "Unsupported architecture for dependency download." ;;
            esac
            ;;
        Win64) OS="windows-amd64" ;;
    esac

    local rclone_bin="$UEBS_TOOLS_DIR/rclone"
    [[ "$OS" == windows* ]] && rclone_bin="${rclone_bin}.exe"

    if ! command -v unzip &>/dev/null; then
        uebs::throw_error "Please install 'unzip' and try again."
    fi

    if [[ ! -f "$rclone_bin" ]]; then
        echo "Downloading rclone ${UEBS_RCLONE_VERSION} ..."
        mkdir -p "$UEBS_TOOLS_DIR"
        local rclone_zip="rclone-${UEBS_RCLONE_VERSION}-${OS}.zip"
        curl -fsSL "https://downloads.rclone.org/${UEBS_RCLONE_VERSION}/${rclone_zip}" -o "$UEBS_TOOLS_DIR/$rclone_zip"
        unzip -jo "$UEBS_TOOLS_DIR/$rclone_zip" "*/rclone*" -d "$UEBS_TOOLS_DIR"
        rm "$UEBS_TOOLS_DIR/$rclone_zip"
        chmod +x "$rclone_bin"

        if [[ ! -f "$rclone_bin" ]]; then
            uebs::throw_error "Failed to download rclone. Please install it manually from https://rclone.org/downloads/ and try again."
        fi
    fi

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue

        IFS='|' read -r remote_name remote_type remote_src local_dst <<< "$entry"

        if [ -z "$remote_name" ] || [ -z "$remote_type" ] || [ -z "$remote_src" ] || [ -z "$local_dst" ]; then
            uebs::print_warning "Skipping malformed dependency entry: '$entry'"
            continue
        fi

        local abs_dst="${UEBS_PROJECT_PATH}/${local_dst}"
        local versions_file="${UEBS_PROJECT_PATH}/.dep_versions"
        local stored
        stored="$(grep "^${remote_name}=" "$versions_file" 2>/dev/null | cut -d'=' -f2-)"

        if [ "$stored" = "$remote_src" ]; then
            echo "'${remote_name}' is already up to date. Skipping."
            continue
        fi

        if ! "$rclone_bin" listremotes | grep -q "^${remote_name}:"; then
            echo "Configuring remote '$remote_name' (type: $remote_type) ..."
            "$rclone_bin" config create "$remote_name" "$remote_type" scope drive.readonly
            if [ $? -ne 0 ]; then
                uebs::throw_error "Failed to configure rclone remote '$remote_name'."
            fi
        fi

        local tmp_zip
        tmp_zip="$(mktemp --suffix=.zip)"

        echo "Downloading '${remote_name}:${remote_src}' ..."
        "$rclone_bin" copyto "${remote_name}:${remote_src}" "$tmp_zip" --progress
        if [ $? -ne 0 ] && [ "$remote_type" == "drive" ]; then
            echo "Retrying with --drive-shared-with-me ..."
            "$rclone_bin" copyto "${remote_name}:${remote_src}" "$tmp_zip" --progress --drive-shared-with-me
        fi
        if [ $? -ne 0 ]; then
            rm -f "$tmp_zip"
            uebs::throw_error "Failed to download '${remote_name}:${remote_src}'."
        fi

        local tmp_extract
        tmp_extract="$(mktemp -d)"

        echo "Extracting to '${abs_dst}' ..."
        unzip -o "$tmp_zip" -d "$tmp_extract"
        if [ $? -ne 0 ]; then
            rm -f "$tmp_zip"
            rm -rf "$tmp_extract"
            uebs::throw_error "Failed to extract '${remote_name}:${remote_src}'."
        fi

        mkdir -p "$abs_dst"
        for item in "$tmp_extract"/*; do
            local item_name
            item_name="$(basename "$item")"
            rm -rf "${abs_dst}/${item_name}"
            mv "$item" "${abs_dst}/${item_name}"
        done

        rm -f "$tmp_zip"
        rm -rf "$tmp_extract"
        sed -i "/^${remote_name}=/d" "$versions_file" 2>/dev/null
        echo "${remote_name}=${remote_src}" >> "$versions_file"

    done <<< "$UEBS_EXTERNAL_DEPENDENCIES"

    uebs::print_success "All external dependencies downloaded."
    echo
}
