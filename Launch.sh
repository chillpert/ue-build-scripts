# Initialize LFS
git lfs install

# Set rebase policy
git config pull.rebase true

# Load Git aliases
git config include.path "../.gitalias"

# Checkout all submodules
git submodule update --init --recursive

~/.local/bin/ue4 build && ~/.local/bin/ue4 run