# ue-build-scripts

This is a collection of scripts for building a C++-based Unreal Engine project on Windows. The goal is to distribute a single script (`Launch.bat`) that everyone will run each time they want to launch the project. This script will also deploy two Git hooks which will analyze changes in source code and determine the new build instructions accordingly. For example, if you switched to a different branch that has added source files, the hooks will trigger compilation the next time the user runs `Launch.bat`.

In other words, artists and designers won't ever have to manually (clean) build the project again. The script will do everything for them without wasting their time. Simultaneously, programmers don't have to inform others when they have to (clean) build or update submodules. It's also a great way to enforce Git-related configurations, e.g. a rebase-policy.

There is also a script for uploading the engine log file to an orphaned Git branch. By default it will attempt to push the log to a branch called `junk/logs`, so you have to make sure that you have a branch of the same name in your game's repository. You can modify a variable in `UploadLogs.bat` if you want to use a different name for the branch.

The setup is supposed to be further simplified in the future.

# Requirements

- Unreal Engine 5
- Git LFS 2.0
- Windows 10 (11 was not tested yet)

# Installation

As submodule:
```
cd MyGameProject
git submodule add https://github.com/chillpert/ue-build-scripts Scripts
```

Without git association:

```
cd MyGameProject
git clone https://github.com/chillpert/ue-build-scripts Scripts
cd Scripts
rmdir /S /Q .git
```

Run `Deploy.bat` everytime you pull from this repo, which will simply copy `Launch/Launch.bat` into your project directory and only run this copy from now on. Other people don't ever have to go inside the ue-build-scripts or scripts folder.

If you are using it as a submodule, make sure to distribute your copy of `Launch.bat` as part of your game repository.
Also make sure that everybody runs `Launch.bat` once, so that the submodule will be properly cloned or updated.

Please take a look at `Launch.bat` and modify it to suit your needs. It is likely that the script will do a few more things you don't want for your project. Simply consider it a template file.
