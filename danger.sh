#!/bin/bash

# Repository names
repos=("rpapub/REFramework-VB-legacy" "rpapub/REFramework-CSharp-legacy" "rpapub/REFramework-VB-Windows" "rpapub/REFramework-CSharp-Windows")

# Delete repositories
for repo in "${repos[@]}"; do
    echo "Deleting repository: $repo"
    gh repo delete "$repo" --yes
done

# Create repositories with minimal features
for repo in "${repos[@]}"; do
    echo "Creating repository: $repo"

    # Create repository using GitHub CLI
    gh repo create "$repo" --public --disable-issues --disable-wiki --description "Extracted UiPath Studio template, @see: https://github.com/rpapub/BuoyantXenon"

    # Initialize a temporary directory for the repository
    TEMP_REPO_DIR=$(mktemp -d)
    cd "$TEMP_REPO_DIR"

    # Initialize the repository locally
    git init
    git remote add origin https://github.com/$repo.git

    # Create a minimal README.md
    echo "# $repo" >README.md
    echo "This repository contains extracted UiPath Studio template for REFramework." >>README.md
    echo "For more information, see the main project: [BuoyantXenon](https://github.com/rpapub/BuoyantXenon)." >>README.md

    # Commit and push the README.md to the repository
    git add README.md
    git commit -m "Initial commit with README"
    git branch -M readme
    git push -u origin readme

    # Clean up
    cd ..
    rm -rf "$TEMP_REPO_DIR"
done
