#!/usr/bin/env bash
# Author: github.com/chillpert

# This script will remove all existing locks even if the file was deleted. 
# @NOTE: Do NOT run this script on uncommitted local changes.

source "$(pwd)/Internal/Library.sh"

uebs::unlock_all

sleep 2
