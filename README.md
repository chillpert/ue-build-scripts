# ue-build-scripts

This is a collection of scripts for building and managing a C++-based Unreal Engine project on Windows. The goal is to distribute a single script (`Launch.bat`) that everyone will run each time they want to launch the project. The script can be modified to run any other operation you like, e.g. cloning Git submodules, setting Git policies, running UBT commands, etc. It's much faster than launching your project using the Epic Games Launcher.

There is also a script for uploading the engine log file to an orphaned Git branch to simplify technical support. By default it will attempt to push the log to a branch called `junk/logs`, so you have to make sure that you have a branch of the same name in your game's repository. You can modify a variable in `UploadLogs.bat` if you want to use a different name for the branch.

# Requirements

- Unreal Engine 5
- Git LFS 2.0
- Windows 10

# Installation

As submodule:
```
cd MyGameProject
git submodule add https://github.com/chillpert/ue-build-scripts Scripts
```

Without Git:

```
cd MyGameProject
git clone https://github.com/chillpert/ue-build-scripts Scripts
cd Scripts
rmdir /S /Q .git
```

Copy `Launch.bat` to your game's root directory and double-click to run the script.

Please take a look at `Launch.bat` and modify it to suit your needs. It is likely that the script will do a few more things you don't want for your project. Simply consider it a template file.