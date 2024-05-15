# ue-build-scripts

This repository contains a few useful scripts to manage your Git-LFS-based Unreal Engine project in a team. Simply
distribute these scripts as part of your game repository and have everyone launch the editor using `Launch.sh` with Git
Bash.

Take a look at `Library.sh` for more explanations and modify it as you need.

### Features

- cross platform (Windows and Linux)
- no external dependencies
- verify installation of Git, Git-LFS, Unreal Engine, VS, DotNet, and other dependencies
- automatically update your feature branch
- enforce global project settings on all machines
- build and launch your C++-based Unreal Engine project
- automatically push the engine log to a special branch so others can easily take a look at it
- generate automated bug reports that automatically link the relevant commit and engine log
- Windows and Linux compatible
- LFS locking tooling (with built-in fzf)
- **Designed for rebase-only policy**

### Requirements

- Git
- Git LFS 2
- Git Bash for Windows (ships with Git)

### Usage

#### Submodule Example

In your game repository run:

```sh
# Add the scripts as a submodule into a folder called Scripts
git submodule add https://github.com/chillpert/ue-build-scripts Scripts

# Commit your changes
git commit -m "Add ue-build-scripts"
git push
```

In the root directory of your game repository add a bash script called `Launch.sh`:

```sh
#!/usr/bin/env bash

# Make sure to always get the desired version of the build scripts before executing them
git submodule update --init --recursive Scripts

# Just saving our current working directory in a variable
cwd="$(pwd || exit)"

# Configure project settings (see Internal/Library.sh for more information)
export UEBS_PROJECT_PATH="$cwd" # This is the project root directory (in most cases cwd)
export UEBS_SCRIPTS_PATH="$cwd/Scripts" # This is the directory of the submodule
export UEBS_ENGINE_VERSION="5.4" # The required version of Unreal Engine
export UEBS_DESIRED_VS_VERSION="2022" # The required version of Visual Studio
export UEBS_DESIRED_DOT_NET_VERSION=6 # The required version of .NET
export UEBS_LOG_BRANCH_NAME="junk/logs" # The branch to upload our engine logs to
export UEBS_GIT_LFS_EXECUTABLE="Plugins/UEGitPlugin/git-lfs" # An optional custom git-lfs executable
export UEBS_DEFAULT_PROJECT_BRANCH="develop" # Our main branch for development purposes (the auto-branch-updater will only consider this branch as a source of updates)

cd Scripts || exit # All of the scripts must be executed inside their folder
./Internal/Launch.sh # Let's execute the actual launch script
```

Make sure everyone in the team only launches the editor using this `Launch.sh` script from now on.

### Other Projects

Consider giving my cross-platform [LFS-Lock-Manager](https://github.com/chillpert/lfs-lock-manager) a try.
