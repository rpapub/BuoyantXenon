#!/bin/bash
set -euo pipefail

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
#   Configure source repo, target owner and subdir->repo mappings in
#   extraction-config.json, then run this script. Requires GITHUB_TOKEN
#   in the environment and jq/git-filter-repo on PATH.
#
# Author: Christian Prior-Mamulyan
# Date: 2023-12-21
# Copyright: Christian Prior-Mamulyan, 2023
# License: This script is released under the CC BY license.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/extraction-config.json}"

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

debug_breakpoint() {
    echo "debug: $1"
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)
    if [ -n "$current_branch" ]; then
        echo "Current branch: $current_branch"
    else
        echo "Not currently on a branch."
    fi
    echo "DEBUG BREAKPOINT: Press Enter to continue..."
    read -r </dev/tty # Waits for the user to press Enter, reading specifically from the terminal
}

# Re-checks every (branch, subdir) pair the main loop recorded as pushed
# successfully, confirming the branch actually exists in the target repo.
# Only logs problems; silence is success.
validate_results() {
    local validation_failures=0

    for key in "${!successes[@]}"; do
        local release_branch="${key%%:*}"
        local subdir_path="${key#*:}"
        local target_repo_name="${subdir_to_repo[$subdir_path]}"
        local target_repo_dir="$TEMP_DIR/$target_repo_name"

        if [ ! -d "$target_repo_dir" ]; then
            log "Validation failed: Target repository directory $target_repo_dir does not exist."
            validation_failures=$((validation_failures + 1))
            continue
        fi

        (cd "$target_repo_dir" && git fetch origin --quiet)

        if ! git -C "$target_repo_dir" rev-parse --verify "origin/$release_branch" >/dev/null 2>&1; then
            log "Validation failed: Branch $release_branch missing on remote for $target_repo_name."
            validation_failures=$((validation_failures + 1))
        fi
    done

    log "Validation complete: $validation_failures problem(s) found."
}

# Extracts $subdir_path out of the already-checked-out $temp_source_dir and
# merges it into a worktree of the matching target repo on branch $branch,
# then pushes. Records the outcome in successes/failures.
process_branch_subdir() {
    local branch="$1"
    local subdir_path="$2"
    local temp_source_dir="$3"

    if [ ! -d "$temp_source_dir/$subdir_path" ]; then
        failures["$branch:$subdir_path"]="Subdirectory does not exist in source"
        return
    fi

    (cd "$temp_source_dir" && git filter-repo --subdirectory-filter "$subdir_path" --force --quiet)

    local target_repo_name="${subdir_to_repo[$subdir_path]}"
    local target_repo_dir="$TEMP_DIR/$target_repo_name"
    if [ ! -d "$target_repo_dir" ]; then
        failures["$branch:$subdir_path"]="Target directory does not exist"
        return
    fi

    local worktree_dir
    worktree_dir="$TEMP_DIR/worktree_${target_repo_name}_${branch//\//-}"
    if git -C "$target_repo_dir" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
        git -C "$target_repo_dir" worktree add --quiet -B "$branch" "$worktree_dir" "origin/$branch"
    else
        git -C "$target_repo_dir" worktree add --quiet -b "$branch" "$worktree_dir"
    fi

    local push_status=0
    if ! (
        cd "$worktree_dir"
        git config pull.rebase false
        git pull -X theirs "$temp_source_dir" "$branch" --allow-unrelated-histories --quiet
        git push origin "$branch" --force --quiet
    ); then
        push_status=1
    fi

    git -C "$target_repo_dir" worktree remove --force "$worktree_dir"

    if [ "$push_status" -ne 0 ]; then
        log "FATAL: push to $target_repo_name failed (branch $branch). Aborting — likely an auth/permission problem affecting all remaining pushes."
        exit 1
    fi

    successes["$branch:$subdir_path"]="Processed successfully"
}

# Define success and failure associative arrays
declare -A successes failures

# Function to cleanup, reset GIT_DIR, and report a final summary
cleanup() {
    echo
    echo "===== Summary ====="
    echo "Succeeded: ${#successes[@]}   Failed: ${#failures[@]}"
    if [ "${#failures[@]}" -gt 0 ]; then
        echo "Failures:"
        for key in "${!failures[@]}"; do
            echo "  $key: ${failures[$key]}"
        done
    fi
    echo "===================="
    unset GIT_DIR
    [ -n "${TEMP_DIR:-}" ] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

if [ ! -f "$CONFIG_FILE" ]; then
    log "FATAL: config file not found at $CONFIG_FILE"
    exit 1
fi

GITHUB_TOKEN=$(echo "${GITHUB_TOKEN:-}" | xargs) #trim whitespace

# Fail fast if the token can't authenticate, before cloning/filtering anything
log "Verifying GitHub token authentication..."
auth_check=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)
if [ "$auth_check" != "200" ]; then
    log "FATAL: GitHub token authentication failed (HTTP $auth_check). Check GITHUB_TOKEN / secret validity."
    exit 1
fi
log "Token authentication OK."

SOURCE_REPO="$(jq -r '.source_repo' "$CONFIG_FILE")"
TARGET_OWNER="$(jq -r '.target_owner' "$CONFIG_FILE")"

# Map each vendor subdir to the target repo it gets extracted into, per
# extraction-config.json (adding a variant is now a config change, not code).
declare -A subdir_to_repo
while IFS=$'\t' read -r subdir_path repo_name; do
    subdir_to_repo["$subdir_path"]="$repo_name"
done < <(jq -r '.mappings[] | [.subdir, .repo] | @tsv' "$CONFIG_FILE")

# Fail fast if the token can authenticate but still lacks push access to any
# target repo — a valid token for the wrong identity/permissions produces a
# 403 on the first push otherwise, after all the clone/filter work is done.
log "Verifying push access to target repos..."
missing_push_access=()
for target_repo_name in $(printf '%s\n' "${subdir_to_repo[@]}" | sort -u); do
    push_access=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$TARGET_OWNER/$target_repo_name" | jq -r '.permissions.push // false')
    if [ "$push_access" != "true" ]; then
        missing_push_access+=("$TARGET_OWNER/$target_repo_name")
    fi
done
if [ "${#missing_push_access[@]}" -gt 0 ]; then
    log "FATAL: GITHUB_TOKEN lacks push access to: ${missing_push_access[*]}"
    exit 1
fi
log "Push access confirmed for all target repos."

# Create a temporary working directory
TEMP_DIR=$(mktemp -d)
log "Created temporary directory at: $TEMP_DIR"

git config --global credential.helper store
echo "https://x-access-token:$GITHUB_TOKEN@github.com" >~/.git-credentials

# Clone the target repositories
log "Cloning target repositories into $TEMP_DIR..."
for target_repo_name in $(printf '%s\n' "${subdir_to_repo[@]}" | sort -u); do
    git clone --quiet "https://x-access-token:$GITHUB_TOKEN@github.com/$TARGET_OWNER/$target_repo_name.git" "$TEMP_DIR/$target_repo_name"
done
log "All target repositories cloned."

# Process each release branch and subdirectory
while read -r branch; do
    log "Processing branch $branch..."

    for subdir_path in "${!subdir_to_repo[@]}"; do
        temp_source_dir="$TEMP_DIR/temp_source_${branch}_${subdir_path//\//-}"
        git clone --quiet "$SOURCE_REPO" "$temp_source_dir"
        git -C "$temp_source_dir" checkout --quiet "$branch"

        process_branch_subdir "$branch" "$subdir_path" "$temp_source_dir"

        rm -rf "$temp_source_dir"
    done
done < <(git ls-remote --heads "$SOURCE_REPO" | grep 'refs/heads/release/v' | awk -F'refs/heads/' '{print $2}')

validate_results
