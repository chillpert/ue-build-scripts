#!/usr/bin/env bash
# Author: github.com/chillpert

# This script will launch fzf to lock any non-locked uasset.

source "$(pwd)/Internal/Library.sh"

cd ..

uebs::lock

cd - 1>/dev/null

sleep 2
