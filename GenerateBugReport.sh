#!/usr/bin/env bash
# Author: github.com/chillpert

# This script attempts to upload the engine log to a special branch in your Git repository that only includes log files.
# Then it will generate a bug report template and automatically fill in the current commit as well as a link to the associated engine log.

source "$(pwd)/Library.sh"

# @NOTE: Modify this to match your desired branch to store log files.
branchName="junk/logs"

uploadEngineLogs() {
    printHeader "Uploading engine log" "${yellow}"

    cd "$projectPath"
    git ls-remote --exit-code --heads origin $branchName
    if [ $? -ne 0 ]; then
        throwError "Failed to upload engine log: The branch $branchName does not exist on the remote. Please create it first and try again."
    fi
    cd - 1> /dev/null

    scriptsPath="basename $(pwd)"
    projectPath="$(cd .. && pwd)"

    projectName=$(cd .. && basename $(pwd))
    logFile="../Saved/Logs/${projectName}.log"

    # Retrieve GitHub url of game repo
    remoteUrl=$(cd .. && git remote get-url origin)

    # Assign a slightly unusual directory name to avoid conflicts and accidental deletion
    stagingDir="${projectName}_logs_staging"

    # Clone single orphan branch called ${branchName}
    git clone --single-branch --depth=1 --branch ${branchName} ${remoteUrl} ${stagingDir}

    # Retrieve current time
    localTime=$(date)

    # Retrieve Git user name
    gitUserName=$(git config user.name)

    # Create the target directory for copying
    mkdir -p "${stagingDir}/Logs"

    # Copy the log file
    cp "${logFile}" "${stagingDir}/Logs/${gitUserName}_${localTime}"

    # Enter the directory of the orphan branch
    cd "${stagingDir}"

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
    rm -rf ${stagingDir}

    echo
}

# @NOTE: Requires uploadEngineLogs to be run before executing this function
generateBugReport () {
    printHeader "Generating bug report and copying to clipboard ..." "${yellow}"

    cd ..
    commitInfo="$(git log -1 --oneline)
$(git config --get remote.origin.url | sed -e 's/\.git$//g')/commit/$(git rev-parse HEAD)"
    cd - 1> /dev/null

    echo "### Description:
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
${logCommitInfo}" | clip
}

uploadEngineLogs
generateBugReport

read -p "Press ENTER to resume ..."