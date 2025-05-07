#!/bin/bash
# test-local.sh - Basic local test script for nsite-action
# This does not actually run the action (you'd need act or similar for that)
# but can be used to test the platform detection logic manually.

set -e  # Exit on error

echo "=== nsite-action Local Test ==="
echo "Note: This does not run the full action, just helps verify platform logic."
echo

# Manually detect OS/ARCH similar to the action
OS=""
ARCH=""
EXE_SUFFIX=""

# Detect OS
case "$(uname -s)" in
  Linux*)     OS="unknown-linux-gnu" ;;
  Darwin*)    OS="apple-darwin" ;;
  MINGW*|MSYS*|CYGWIN*) 
    OS="pc-windows-msvc"
    EXE_SUFFIX=".exe"
    ;;
  *)          echo "Unsupported OS: $(uname -s)" && exit 1 ;;
esac

# Detect architecture
case "$(uname -m)" in
  x86_64)     ARCH="x86_64" ;;
  aarch64|arm64) ARCH="aarch64" ;;
  *)          echo "Unsupported architecture: $(uname -m)" && exit 1 ;;
esac

echo "Detected OS: $OS"
echo "Detected ARCH: $ARCH"
echo "Asset suffix would be: $ARCH-$OS"

# Check if gh CLI is available and authenticated
echo
echo "Checking GitHub CLI..."
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) not installed. Action would fall back to API."
else
  echo "GitHub CLI found. Checking authentication..."
  if gh auth status &> /dev/null; then
    echo "GitHub CLI authenticated."
    echo "Would use: gh release list -R sandwichfarm/nsyte"
  else
    echo "GitHub CLI not authenticated. Action would fall back to API."
  fi
fi

# Create a test directory
echo
echo "Creating test directory and file..."
mkdir -p "test-local-dir"
echo "<html><body>Test page</body></html>" > "test-local-dir/index.html"
echo "Created test-local-dir/index.html"

echo
echo "Would construct command like:"
echo "./nsyte${EXE_SUFFIX} upload './test-local-dir' --nbunksec 'nbunksec...' [FLAGS]"

echo
echo "=== Test Complete ==="
echo "To run the actual action, you'd need to:"
echo "1. Push this repo to GitHub"
echo "2. Set up appropriate secrets"
echo "3. Run the workflow in Actions tab or use 'act' locally" 