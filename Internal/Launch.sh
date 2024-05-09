#!/usr/bin/env bash
# Author: github.com/chillpert

# This script is your all-in-one solution to verify, build, and run your project.

source "$(pwd)/Internal/Library.sh"

# Execute all core-functions
uebs::check_dependencies
uebs::prepare
uebs::update
uebs::fetch
uebs::build
uebs::run

# Wait a bit before closing
sleep 2.5