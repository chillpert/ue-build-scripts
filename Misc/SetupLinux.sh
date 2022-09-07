#!/usr/bin/env bash

cd ..

# Initialize LFS
git lfs install

# Set rebase policy
git config pull.rebase true

# Load Git aliases
git config include.path "../.gitalias"

# Checkout all submodules
git submodule update --init --recursive

# Copy Git hooks to hooks directory
cp Scripts/Hooks/* .git/hooks

# For building the project, Linux users are supposed to use ue4-cli (https://github.com/adamrehn/ue4cli)

cd Scripts