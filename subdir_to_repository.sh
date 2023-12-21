#!/bin/bash

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
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
    log "Cleanup complete."
}
trap cleanup EXIT

# Define the source repository and target repositories
SOURCE_REPO="https://github.com/UiPath-Services/StudioTemplates.git"
REPO1="https://github.com/rpapub/REFramework-VB-legacy.git"
REPO1="git@github.com:rpapub/REFramework-VB-legacy.git"
REPO2="https://github.com/rpapub/REFramework-CSharp-legacy.git"
REPO2="git@github.com:rpapub/REFramework-CSharp-legacy.git"
REPO3="https://github.com/rpapub/REFramework-VB-Windows.git"
REPO3="git@github.com:rpapub/REFramework-VB-Windows.git"
REPO4="https://github.com/rpapub/REFramework-CSharp-Windows.git"
REPO4="git@github.com:rpapub/REFramework-CSharp-Windows.git"

# Define subdirectories and their corresponding target repos
declare -A subdirs
subdirs["REFramework/contentFiles/any/any/pt0/VisualBasic"]="REFramework-VB-legacy"
subdirs["REFramework/contentFiles/any/any/pt1/CSharp"]="REFramework-CSharp-legacy"
subdirs["REFramework/contentFiles/any/any/pt2/VisualBasic"]="REFramework-VB-Windows"
subdirs["REFramework/contentFiles/any/any/pt3/CSharp"]="REFramework-CSharp-Windows"

# Create a temporary working directory
TEMP_DIR=$(mktemp -d)
log "Created temporary directory at: $TEMP_DIR"

# Clone the source repository as non-bare into a subfolder
log "Cloning source repository (non-bare) into $TEMP_DIR/source_repo_non_bare..."
git clone $SOURCE_REPO "$TEMP_DIR/source_repo_non_bare"
log "Source repository (non-bare) cloned."

# Also clone the source repository as bare to use for fetching
log "Cloning source repository (bare) into $TEMP_DIR/source_repo_bare..."
git clone --bare $SOURCE_REPO "$TEMP_DIR/source_repo_bare"
log "Source bare repository cloned."

# Clone the target repositories
log "Cloning target repositories into $TEMP_DIR..."
git clone $REPO1 "$TEMP_DIR/REFramework-VB-legacy"
git clone $REPO2 "$TEMP_DIR/REFramework-CSharp-legacy"
git clone $REPO3 "$TEMP_DIR/REFramework-VB-Windows"
git clone $REPO4 "$TEMP_DIR/REFramework-CSharp-Windows"
log "All target repositories cloned."

# Process each release branch
cd "$TEMP_DIR/source_repo_non_bare"
log "Fetching all branches in the non-bare source repository..."
git fetch --all
log "Starting to process branches..."

while read remote_branch; do
    branch=${remote_branch#origin/}
    log "Processing branch $branch..."

    # Checkout each release branch
    git checkout $branch
    log "Checked out branch $branch in source repository."

    for subdir in "${!subdirs[@]}"; do
        target_repo_dir="$TEMP_DIR/${subdirs[$subdir]}"
        log "Processing subdirectory $subdir for target repository $target_repo_dir..."

        if [ -d "$target_repo_dir" ]; then
            log "Changing to target repository directory: $target_repo_dir"
            cd "$target_repo_dir"

            # Fetch and checkout the specific branch from the source repository
            log "Fetching branch $branch from bare source repository..."
            git fetch "$TEMP_DIR/source_repo_bare" "$branch"
            log "Checking out branch $branch in target repository..."
            git checkout -b "$branch" FETCH_HEAD

            # Record successful operation
            successes["$branch:$subdir"]="Processed successfully"
            log "Completed operations on branch $branch for subdirectory $subdir."

            # Push the changes to the remote target repository
            log "Pushing branch $branch to the remote target repository..."
            git push origin "$branch"

            # Switch back to the non-bare source repository to continue
            cd "$TEMP_DIR/source_repo_non_bare"
        else
            log "Target repository directory $target_repo_dir does not exist."
            # Record failure
            failures["$branch:$subdir"]="Directory does not exist"
        fi
    done
done < <(git branch -r | grep 'origin/release/v')

log "Script execution completed."

