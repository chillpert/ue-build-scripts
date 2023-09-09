# ue-build-scripts

This repository contains a few useful scripts to manage your Git-LFS-based Unreal Engine project in a team. Simply distribute these scripts as part of your game repository and have everyone launch the editor using `Launch.sh` with Git Bash.

Simply take a look at `Library.sh` and modify it to match your own needs.

### Features

- cross platform (Windows and Linux)
- no external dependencies
- verify installation of Git, Git-LFS, Unreal Engine, VS, DotNet, and other dependencies
- enforce global project settings on all machines
- build and launch your C++-based Unreal Engine project
- automatically push the engine log to a special branch so others can easily take a look at it
- generate automated bug reports that automatically link the relevant commit and engine log
- Windows and Linux compatible
- LFS locking tooling (with built-in fzf)

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

# Download the scripts for people who forget about `--recursive` when cloning
git submodule update --init --recursive Scripts

cd Scripts
./Launch.sh
```

Make sure everyone in the team only launches the editor using this `Launch.sh` script from now on.
