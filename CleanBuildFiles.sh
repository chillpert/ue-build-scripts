#!/usr/bin/env bash
# Author: github.com/chillpert

source "$(pwd)/Library.sh"

printHeader "Cleaning $projectName build files ..."

rm -rf "$projectPath/Binaries" "$projectPath/Intermediate" "$projectPath/*.sln"

printWarning "Now you may run 'Launch.sh' again."
echo 

waitForInput