# ue-scripts

This repository contains a few useful scripts to manage your Git-LFS-based Unreal Engine project in a team.
Simply distribute these scripts as part of your game's repository and have everyone launch the editor using
`Launch.sh` with Git Bash.

### Features

- verify installation of Git, Git-LFS, a given version of Unreal Engine 
- enforce an identical Git configuration on all machines
- build and launch your C++-based Unreal Engine project
- automatically push the engine log to a special branch so others can easily take a look at it
- generate automated bug reports that include automatically link the relevant commit and engine log
- [TODO] cross-platform support (on Linux using ue4cli)

### Requirements

- Git
- Git LFS 2
- Git Bash for Windows