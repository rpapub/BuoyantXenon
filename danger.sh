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
    gh repo create "$repo" --public --disable-issues --disable-wiki --description "WIP -- do not use"
    # Use --private instead of --public for private repositories
done
