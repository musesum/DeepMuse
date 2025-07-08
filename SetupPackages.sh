#!/bin/bash
set -e

# Determine the parent directory of the current directory.
# This assumes that your main app is in a folder and you want "Mu Packages" to be its sibling.
BASE_DIR="$(dirname "$PWD")"
MU_PACKAGES_DIR="$BASE_DIR/Mu"

echo "Creating directory: $MU_PACKAGES_DIR"
mkdir -p "$MU_PACKAGES_DIR"

# Change into the Mu Packages directory.
cd "$MU_PACKAGES_DIR"

# List of repositories to clone.
REPOS=(
  "https://github.com/musesum/MuPeer"
  "https://github.com/musesum/MuAudio"
  "https://github.com/musesum/MuPlato"
  "https://github.com/musesum/MuFlo"
  "https://github.com/musesum/MuVision"
  "https://github.com/musesum/MuMenu"
  "https://github.com/musesum/MuSky"
)

# Loop through each repo and clone it if it hasn't been cloned already.
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo")
    if [ -d "$repo_name" ]; then
        echo "Repository '$repo_name' already exists. Skipping..."
    else
        echo "Cloning $repo ..."
        git clone "$repo"
    fi
done

echo "All repositories have been cloned into '$MU_PACKAGES_DIR'."
