#!/bin/bash
# test-local.sh - Basic local test script for nsite-action
# This does not actually run the action, just helps verify platform logic.

set -e  # Exit on error

echo "=== nsite-action Local Test ==="
echo "Note: This does not run the full action, just helps verify platform logic."
echo

# Manually detect platform similar to the action
PLATFORM=""
EXE_SUFFIX=""

# Detect OS (simplified to match asset naming pattern)
case "$(uname -s)" in
  Linux*)     PLATFORM="linux" ;;
  Darwin*)    PLATFORM="macos" ;;
  MINGW*|MSYS*|CYGWIN*) 
    PLATFORM="windows"
    EXE_SUFFIX=".exe"
    ;;
  *)          echo "Unsupported OS: $(uname -s)" && exit 1 ;;
esac

echo "Detected platform: $PLATFORM"
VERSION_FOR_FILENAME="0.0.0" # Placeholder for local test
FAKE_BINARY_NAME="nsyte-$PLATFORM-$VERSION_FOR_FILENAME$EXE_SUFFIX"
echo "Binary name would be like: $FAKE_BINARY_NAME"

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
    
    echo
    echo "Available nsyte releases (most recent first):"
    gh release list --limit 5 -R sandwichfarm/nsyte 2>/dev/null || echo "Could not fetch releases."
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
echo "Checking action metadata..."
if ! grep -qE '^  name:$' action.yml; then
  echo "Missing named-site action input: name"
  exit 1
fi
if ! grep -q -- '--name' action.yml || ! grep -q -- 'inputs.name' action.yml; then
  echo "Missing nsyte --name forwarding in action.yml"
  exit 1
fi
echo "Named-site input is present and forwarded to nsyte."

if grep -qF 'steps.build_cmd.outputs.command' action.yml || grep -qF 'eval "$NSYT_COMMAND"' action.yml; then
  echo "Unsafe command-output/eval deploy path is still present in action.yml"
  exit 1
fi
if ! grep -qF 'CMD=(' action.yml || ! grep -qF '"${CMD[@]}"' action.yml; then
  echo "Missing Bash array deploy execution in action.yml"
  exit 1
fi
echo "Deploy command uses a Bash argument array instead of eval."

# Define dummy relays and servers for example
TEST_RELAYS="wss://relay.example.com,wss://nostr.example.org"
TEST_SERVERS="https://blossom.example.com"
TEST_SITE_NAME="blog"

echo
echo "Would construct command like:"
echo "$FAKE_BINARY_NAME deploy './test-local-dir' --sec '<nsec|nbunksec1|bunker://|hex>' --relays '$TEST_RELAYS' --servers '$TEST_SERVERS' --name '$TEST_SITE_NAME' [OTHER_FLAGS]"

echo
echo "=== Test Complete ==="
echo "To run the actual action, you'd need to:"
echo "1. Push this repo to GitHub"
echo "2. Set up appropriate secrets (SEC - passed to nsyte via --sec and accepts nsec, nbunksec, bunker://, or hex)"
echo "3. Configure relays and servers in your workflow"
echo "4. Run the workflow in Actions tab or use 'act' locally" 
