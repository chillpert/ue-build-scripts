# ue-build-scripts

This is a collection of scripts for building a C++-based Unreal Engine project on Windows. Whenever somebody creates a commit that modifies source code, a Git hook will automatically update a build status file, which will be generated in the `Source` directory. Depending on the type of changes, it will either trigger a build or a clean build for everyone who pulls this commit as long as they always run the project using the `Launch.bat` script. The script also recursively updates all submodules added to the project.

In other words, artists and designers won't ever have to manually (clean) build the project again. The script will do everything for them without wasting their time. Simultaneously, programmers don't have to inform others when they have to (clean) build or update submodules. It's also a great way to enforce Git-related configurations, e.g. a rebase-policy.

There is also a script for uploading the engine log file to an orphaned Git branch. By default it will attempt to push the log to a branch called `junk/logs`, so you have to make sure that you have a branch of the same name in your game's repository. You can modify a variable in `UploadLogs.bat` if you want to use a different name for the branch.

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
