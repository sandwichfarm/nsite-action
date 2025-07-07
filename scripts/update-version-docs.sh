#!/bin/bash

# Update README.md with versions from versions.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSIONS_FILE="$ROOT_DIR/versions.json"
README_FILE="$ROOT_DIR/README.md"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi

# Read versions
NSYTE_VERSION=$(jq -r '.tools.nsyte.version' "$VERSIONS_FILE")
NSITE_CLI_VERSION=$(jq -r '.tools."nsite-cli".version' "$VERSIONS_FILE")
NOUS_CLI_VERSION=$(jq -r '.tools."nous-cli".version' "$VERSIONS_FILE")
NOSTR_DEPLOY_CLI_VERSION=$(jq -r '.tools."nostr-deploy-cli".version' "$VERSIONS_FILE")

# Update README.md
sed -i.bak -E "s/- \*\*nsyte\*\*: v[0-9]+\.[0-9]+\.[0-9]+/- **nsyte**: $NSYTE_VERSION/" "$README_FILE"
sed -i.bak -E "s/- \*\*nsite-cli\*\*: [0-9]+\.[0-9]+\.[0-9]+/- **nsite-cli**: $NSITE_CLI_VERSION/" "$README_FILE"
sed -i.bak -E "s/- \*\*nous-cli\*\*: [0-9]+\.[0-9]+\.[0-9]+/- **nous-cli**: $NOUS_CLI_VERSION/" "$README_FILE"
sed -i.bak -E "s/- \*\*nostr-deploy-cli\*\*: [0-9]+\.[0-9]+\.[0-9]+/- **nostr-deploy-cli**: $NOSTR_DEPLOY_CLI_VERSION/" "$README_FILE"

# Clean up backup
rm -f "$README_FILE.bak"

echo "Updated README.md with versions from versions.json"
echo "  nsyte: $NSYTE_VERSION"
echo "  nsite-cli: $NSITE_CLI_VERSION"
echo "  nous-cli: $NOUS_CLI_VERSION"
echo "  nostr-deploy-cli: $NOSTR_DEPLOY_CLI_VERSION"