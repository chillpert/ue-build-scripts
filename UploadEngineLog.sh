#!/usr/bin/env bash
# Author: github.com/chillpert

# This script attempts to upload the engine log to a special branch in your Git repository that only includes log files.
# Then it will generate a bug report template and automatically fill in the current commit as well as a link to the associated engine log.

source "$(pwd)/Internal/Library.sh"

# @NOTE: Modify this to match your desired branch to store log files.
branchName="junk/logs"

uploadEngineLogs

read -p "Press ENTER to resume ..."