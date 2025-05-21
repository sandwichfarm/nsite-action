#!/bin/bash
# tag.sh - Creates a git tag based on the version in the VERSION file
# Ported from tag.ts

set -e

# Ensure we're in the root directory of the project
cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

# Check if VERSION file exists
VERSION_FILE="$ROOT_DIR/VERSION"
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    exit 1
fi

# Read the version from VERSION file
VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')

# Validate semver format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.].+)?$ ]]; then
    echo "Error: Version \"$VERSION\" in VERSION file is not a valid semantic version."
    exit 1
fi

echo "Source version from VERSION file: $VERSION"
GIT_TAG_VERSION="v$VERSION"

# Check status of specific files
# FILES_STATUS=$(git status --porcelain "VERSION" "action.yml" "README.md" 2>/dev/null)
# COMMITTED_FILES=false

# if [ -n "$FILES_STATUS" ]; then
#     echo "Committing changes to version-related files..."
#     git add "VERSION" "action.yml" "README.md" 
    
#     COMMIT_MESSAGE="chore: bump version to $VERSION"
#     COMMIT_OUTPUT=$(git commit -m "$COMMIT_MESSAGE" 2>&1) || true
    
#     if echo "$COMMIT_OUTPUT" | grep -q "nothing to commit"; then
#         echo "Nothing to commit. Monitored files are already in the desired state."
#     else
#         echo "Successfully committed version update: $VERSION"
#         COMMITTED_FILES=true
#     fi
# else
#     echo "No changes in version-related files to commit."
# fi

# Check if there are other uncommitted changes
# GENERAL_STATUS=$(git status --porcelain | grep -v "VERSION" | grep -v "action.yml" | grep -v "README.md")
# if [ -n "$GENERAL_STATUS" ] && [ "$COMMITTED_FILES" != "true" ]; then
#     echo "Warning: Uncommitted changes detected in other files. Please commit or stash them if they should not be part of the version tag $GIT_TAG_VERSION."
#     echo "$GENERAL_STATUS"
# fi

# Check if tag already exists locally
if git tag -l "$GIT_TAG_VERSION" | grep -q "$GIT_TAG_VERSION"; then
    echo "Git tag $GIT_TAG_VERSION already exists locally."
    read -p "Overwrite it? (y/N): " OVERWRITE
    
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Deleting local tag $GIT_TAG_VERSION..."
        if ! git tag -d "$GIT_TAG_VERSION"; then
            echo "Error deleting local tag $GIT_TAG_VERSION"
            exit 1
        fi
        echo "Successfully deleted local tag $GIT_TAG_VERSION."
    else
        echo "Skipping tag creation."
        exit 0
    fi
fi

echo "Creating git tag $GIT_TAG_VERSION..."
if git tag "$GIT_TAG_VERSION"; then
    echo "Successfully created git tag $GIT_TAG_VERSION."
    echo "Run 'git push --tags' to publish it or 'make release' to create a GitHub release."
else
    echo "Error creating git tag $GIT_TAG_VERSION"
    exit 1
fi 