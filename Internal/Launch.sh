#!/usr/bin/env bash
# Author: github.com/chillpert

# This script is your all-in-one solution to verify, build, and run your project.

source "$(pwd)/Internal/Library.sh"

checkDependencies
prepare
fetch
build
run

sleep 2.5