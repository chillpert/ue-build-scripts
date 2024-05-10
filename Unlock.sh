#!/usr/bin/env bash
# Author: github.com/chillpert

# This script will launch fzf to remove any of the current user's file locks.

source "$(pwd)/Internal/Library.sh"

cd ..

uebs::unlock

cd - 1>/dev/null

sleep 2
