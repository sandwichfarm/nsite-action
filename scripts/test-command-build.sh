#!/bin/bash
# Runs the action deploy step locally with a fake nsyte binary to catch shell
# quoting regressions in multiline relay/server inputs.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

STEP_SCRIPT="$TMP_DIR/nsyte-run-step.sh"
FAKE_NSYTE="$TMP_DIR/nsyte"
CAPTURE_ARGS="$TMP_DIR/argv.txt"
GITHUB_OUTPUT_FILE="$TMP_DIR/github-output.txt"

ruby -e '
  require "yaml"
  action = YAML.load_file(ARGV.fetch(0))
  step = action.fetch("runs").fetch("steps").find { |candidate| candidate["name"] == "Run nsyte deploy" }
  abort "Run nsyte deploy step not found" unless step
  puts step.fetch("run")
' "$ROOT_DIR/action.yml" > "$STEP_SCRIPT"
chmod +x "$STEP_SCRIPT"

cat > "$FAKE_NSYTE" <<'FAKE'
#!/bin/bash
set -euo pipefail

if [[ "${1:-}" == "deploy" && "${2:-}" == "--help" ]]; then
  echo "Usage: nsyte deploy"
  echo "  --skip-secrets-scan"
  echo "  --scan-level <level>"
  exit 0
fi

printf '%s\n' "$@" > "$NSYTE_CAPTURE_ARGS"
exit "${NSYTE_FAKE_EXIT:-0}"
FAKE
chmod +x "$FAKE_NSYTE"

run_step() {
  : > "$CAPTURE_ARGS"
  : > "$GITHUB_OUTPUT_FILE"
  NSYTE_PATH="$FAKE_NSYTE" \
  NSYTE_VERSION="v0.27.0" \
  INPUT_SEC="" \
  INPUT_NBUNKSEC="nbunksec1testcredential" \
  INPUT_DIRECTORY="./dist" \
  INPUT_RELAYS=$'wss://relay.damus.io\nwss://nos.lol\nwss://relay.nsite.lol\nwss://relay.nosto.re/\nwss://nsite.run' \
  INPUT_SERVERS=$'https://cdn.hzrd149.com/\nhttps://cdn.sovbit.host\nhttps://nostr.download \nhttps://nsite.run\nhttps://blssm.us' \
  INPUT_NAME="blog" \
  INPUT_FORCE="false" \
  INPUT_SYNC="false" \
  INPUT_VERBOSE="false" \
  INPUT_FALLBACK="" \
  INPUT_CONCURRENCY="4" \
  INPUT_PUBLISH_SERVER_LIST="false" \
  INPUT_PUBLISH_RELAY_LIST="false" \
  INPUT_PUBLISH_PROFILE="false" \
  INPUT_USE_FALLBACK_RELAYS="false" \
  INPUT_USE_FALLBACK_SERVERS="false" \
  INPUT_PUBLISH_APP_HANDLER="false" \
  INPUT_HANDLER_KINDS="" \
  INPUT_SKIP_SECRETS_SCAN="true" \
  INPUT_SCAN_LEVEL="" \
  NSYTE_CAPTURE_ARGS="$CAPTURE_ARGS" \
  GITHUB_OUTPUT="$GITHUB_OUTPUT_FILE" \
  "$STEP_SCRIPT"
}

echo "Checking deploy argv construction..."
run_step > "$TMP_DIR/success.log"

EXPECTED_ARGS="$TMP_DIR/expected-argv.txt"
cat > "$EXPECTED_ARGS" <<'EXPECTED'
deploy
./dist
-i
--sec
nbunksec1testcredential
--relays
wss://relay.damus.io,wss://nos.lol,wss://relay.nsite.lol,wss://relay.nosto.re/,wss://nsite.run
--servers
https://cdn.hzrd149.com/,https://cdn.sovbit.host,https://nostr.download,https://nsite.run,https://blssm.us
--name
blog
--concurrency
4
--skip-secrets-scan
EXPECTED

if ! diff -u "$EXPECTED_ARGS" "$CAPTURE_ARGS"; then
  echo "Deploy argv did not match expected multiline input normalization."
  exit 1
fi

if ! grep -q '^status=success$' "$GITHUB_OUTPUT_FILE"; then
  echo "Successful fake nsyte run did not set status=success."
  exit 1
fi

echo "Checking deploy failure propagation..."
NSYTE_FAKE_EXIT=23 run_step > "$TMP_DIR/failure.log"

if ! grep -q '^COMMAND_EXIT_CODE=23$' "$TMP_DIR/failure.log"; then
  echo "Failed fake nsyte run did not report the command exit code."
  exit 1
fi
if ! grep -q '^status=failure$' "$GITHUB_OUTPUT_FILE"; then
  echo "Failed fake nsyte run did not set status=failure."
  exit 1
fi
if ! grep -q '^exit_code=23$' "$GITHUB_OUTPUT_FILE"; then
  echo "Failed fake nsyte run did not set exit_code=23."
  exit 1
fi

echo "Deploy command construction test passed."
