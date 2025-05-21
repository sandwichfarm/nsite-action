#!/bin/bash
# release.sh - Create a GitHub release from the latest tag
# Minimal implementation with fallbacks for GitHub CLI or direct API

set -e

# Ensure we're in the root directory of the project
cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
    echo "Error: No git tags found. Run 'make tag' first to create a tag."
    exit 1
fi

echo "Creating GitHub release for tag: $LATEST_TAG"

# Get repo info from git remote
REPO_URL=$(git remote get-url origin)
if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    if [[ "$REPO" == *.git ]]; then
        REPO="${REPO%.git}"
    fi
else
    echo "Error: Unable to determine GitHub repository from git remote URL."
    echo "Please ensure you have a GitHub remote configured."
    exit 1
fi

echo "Repository: $OWNER/$REPO"

# # Generate release notes from git log (commits since previous tag)
# PREV_TAG=$(git describe --tags --abbrev=0 "$LATEST_TAG^" 2>/dev/null || echo "")
# if [ -n "$PREV_TAG" ]; then
#     echo "Generating release notes from commits since $PREV_TAG"
#     RELEASE_NOTES=$(git log --pretty=format:"- %s" "$PREV_TAG..$LATEST_TAG")
# else
#     echo "No previous tag found, using all commits for release notes"
#     RELEASE_NOTES=$(git log --pretty=format:"- %s" "$LATEST_TAG")
# fi

# Default release title
RELEASE_TITLE="Release $LATEST_TAG"

# Try to create release using GitHub CLI if available
if command -v gh &>/dev/null; then
    echo "Using GitHub CLI to create release"
    
    # Check if GH_TOKEN is available or if we're already authenticated
    if ! gh auth status &>/dev/null; then
        echo "Warning: GitHub CLI is not authenticated. Please run 'gh auth login' or set GH_TOKEN."
        echo "Falling back to creating release manually..."
        echo ""
        echo "To create this release, go to:"
        echo "https://github.com/$OWNER/$REPO/releases/new?tag=$LATEST_TAG"
        echo ""
        echo "With title: $RELEASE_TITLE"
        echo ""
        # echo "And release notes:"
        # echo "$RELEASE_NOTES"
        exit 0
    fi
    
    # Create a temporary file for release notes
    TEMP_NOTES=$(mktemp)
    echo "$RELEASE_NOTES" > "$TEMP_NOTES"
    
    # Create the release
    if gh release create "$LATEST_TAG" \
        --title "$RELEASE_TITLE" \
        --notes-file "$TEMP_NOTES" \
        --repo "$OWNER/$REPO"; then
        echo "Successfully created GitHub release for $LATEST_TAG"
        rm "$TEMP_NOTES"
    else
        echo "Error creating GitHub release"
        rm "$TEMP_NOTES"
        exit 1
    fi
else
    echo "GitHub CLI not found. Please install it for easier release creation."
    echo "Alternatively, you can create this release manually at:"
    echo "https://github.com/$OWNER/$REPO/releases/new?tag=$LATEST_TAG"
    echo ""
    echo "With title: $RELEASE_TITLE"
    echo ""
    # echo "And release notes:"
    # echo "$RELEASE_NOTES"
fi

echo "Release process completed." 