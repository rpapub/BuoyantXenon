#!/bin/bash

# UiPath Studio Template Extraction
#
# Purpose:
#   This script automates the process of extracting specific subdirectories
#   from a source Git repository and migrating them into separate repositories.
#   It is particularly useful for handling projects like UiPath Studio templates,
#   enabling the creation of forkable template repositories for different versions
#   (e.g., legacy/Windows and VB/CSharp) in an organized and efficient manner.
#
# Usage:
#   Set the source repository, target repositories, and desired subdirectories.
#   Run the script to clone the source, filter the specified subdirectories,
#   and push them to the corresponding new repositories.
#
# Author: Christian Prior-Mamulyan
# Date: 2023-12-21
# Copyright: Christian Prior-Mamulyan, 2023
# License: This script is released under the CC BY license.

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

debug_breakpoint() {
    echo "debug: $1"
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$current_branch" ]; then
        echo "Current branch: $current_branch"
    else
        echo "Not currently on a branch."
    fi
    echo "DEBUG BREAKPOINT: Press Enter to continue..."
    read -r </dev/tty # Waits for the user to press Enter, reading specifically from the terminal
}

# Function to validate the results
validate_results() {
    log "Starting validation of results..."

    for branch in "${!subdirs[@]}"; do
        # shellcheck disable=SC2066
        for subdir in "${subdirs[$branch]}"; do
            local target_repo_dir="$TEMP_DIR/$subdir"
            local target_branch="release/$branch"
            local target_subdir="${subdirs[$branch]}"

            if [ ! -d "$target_repo_dir" ]; then
                log "Validation failed: Target repository directory $target_repo_dir does not exist."
                continue
            fi

            cd "$target_repo_dir" || exit

            # Check if the branch exists and has the expected content
            if git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
                log "Checking content in $target_repo_dir on branch $target_branch..."

                # Fetch and check out the target branch
                git fetch origin
                git checkout "$target_branch"

                # Check if the expected subdirectory exists in the target branch
                if [ ! -d "$target_subdir" ]; then
                    log "Validation failed: Subdirectory $target_subdir does not exist in branch $target_branch of $target_repo_dir."
                else
                    log "Validation successful: Subdirectory $target_subdir exists in branch $target_branch of $target_repo_dir."
                fi
            else
                log "Validation failed: Branch $target_branch does not exist in $target_repo_dir."
            fi
        done
    done

    log "Validation of results completed."
}

# Define success and failure associative arrays
declare -A successes failures

# Function to cleanup, reset GIT_DIR, and report outcomes
cleanup() {
    log "Cleanup started. Summarizing actions..."
    echo "Successful operations:"
    for key in "${!successes[@]}"; do
        echo "$key: ${successes[$key]}"
    done

    echo "Failed operations:"
    for key in "${!failures[@]}"; do
        echo "$key: ${failures[$key]}"
    done
    unset GIT_DIR
    rm -rf "$TEMP_DIR"
    log "Cleanup complete."
}
trap cleanup EXIT

# Define the source repository and target repositories using HTTPS URLs
SOURCE_REPO="https://github.com/UiPath-Services/StudioTemplates.git"
REPO1="https://x-access-token:$GITHUB_TOKEN@github.com/rpapub/REFramework-VB-legacy.git"
REPO2="https://x-access-token:$GITHUB_TOKEN@github.com/rpapub/REFramework-CSharp-legacy.git"
REPO3="https://x-access-token:$GITHUB_TOKEN@github.com/rpapub/REFramework-VB-Windows.git"
REPO4="https://x-access-token:$GITHUB_TOKEN@github.com/rpapub/REFramework-CSharp-Windows.git"

# Define subdirectories and their corresponding target repos
declare -A subdirs
subdirs["REFramework/contentFiles/any/any/pt0/VisualBasic"]="REFramework-VB-legacy"
subdirs["REFramework/contentFiles/any/any/pt1/CSharp"]="REFramework-CSharp-legacy"
subdirs["REFramework/contentFiles/any/any/pt2/VisualBasic"]="REFramework-VB-Windows"
subdirs["REFramework/contentFiles/any/any/pt3/CSharp"]="REFramework-CSharp-Windows"

# Create a temporary working directory
TEMP_DIR=$(mktemp -d)
log "Created temporary directory at: $TEMP_DIR"

git config --global credential.helper store
echo "https://x-access-token:$GITHUB_TOKEN@github.com" >~/.git-credentials
GITHUB_TOKEN=$(echo $GITHUB_TOKEN | xargs) #trim whitespace

# Clone the target repositories using SSH URLs
log "Cloning target repositories into $TEMP_DIR using HTTPS URLs..."
git clone --quiet $REPO1 "$TEMP_DIR/REFramework-VB-legacy"
git clone --quiet $REPO2 "$TEMP_DIR/REFramework-CSharp-legacy"
git clone --quiet $REPO3 "$TEMP_DIR/REFramework-VB-Windows"
git clone --quiet $REPO4 "$TEMP_DIR/REFramework-CSharp-Windows"
log "All target repositories cloned."

# Process each release branch and subdirectory
while read -r branch; do

    log "Processing branch $branch..."

    for subdir in "${!subdirs[@]}"; do
        log "Processing subdirectory $subdir for branch $branch..."

        # Clone the source repository into a temporary folder for this specific branch and subdirectory
        temp_source_dir="$TEMP_DIR/temp_source_${branch}_${subdir//\//-}"
        git clone --quiet $SOURCE_REPO "$temp_source_dir"
        cd "$temp_source_dir" || exit

        # Checkout the specific branch
        git checkout "$branch"

        # Check if the subdirectory exists in this branch
        log "Checking if $subdir exists in branch $branch"
        if [ -d "$subdir" ]; then
            log "Subdirectory $subdir exists in branch $branch. Processing..."
            # Filter the repo to only include the specific subdirectory
            git filter-repo --subdirectory-filter "$subdir" --force
            log "Finished filtering the repo"

            # Now handle the target repository
            target_repo_dir="$TEMP_DIR/${subdirs[$subdir]}"
            if [ -d "$target_repo_dir" ]; then
                cd "$target_repo_dir" || exit

                git config pull.rebase false

                # Fetch the latest changes from the remote repository
                git fetch origin --quiet

                # Check if the branch already exists
                if git rev-parse --verify "$branch" >/dev/null 2>&1; then
                    # Checkout the branch
                    git checkout "$branch" --quiet
                else
                    # Create a new branch
                    git checkout -b "$branch" --quiet
                fi

                # Now pull the changes from the filtered source repository with the 'theirs' strategy
                git pull -X theirs "$temp_source_dir" "$branch" --allow-unrelated-histories --quiet

                # Push the changes to the remote target repository
                log "Pushing branch $branch to the remote target repository..."
                git push origin "$branch" --force --quiet

                successes["$branch:$subdir"]="Processed successfully"
            else
                failures["$branch:$subdir"]="Target directory does not exist"
            fi

            # Cleanup: remove the temporary source directory
            rm -rf "$temp_source_dir"
        else
            log "Subdirectory $subdir does not exist in branch $branch. Skipping..."
            failures["$branch:$subdir"]="Subdirectory does not exist in source"
        fi
    done
done < <(git ls-remote --heads $SOURCE_REPO | grep 'refs/heads/release/v' | awk -F'refs/heads/' '{print $2}')

# Call the validation function at the end of the script
validate_results

# Print successes and failures
echo "Successful operations:"
for key in "${!successes[@]}"; do
    echo "$key: ${successes[$key]}"
done

echo "Failed operations:"
for key in "${!failures[@]}"; do
    echo "$key: ${failures[$key]}"
done

log "Script execution completed."
