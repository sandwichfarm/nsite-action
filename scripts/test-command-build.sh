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
VALIDATE_FILES="$TMP_DIR/validate-files.txt"
GITHUB_OUTPUT_FILE="$TMP_DIR/github-output.txt"
RUNNER_TEMP_DIR="$TMP_DIR/runner-temp"
WORKSPACE_DIR="$TMP_DIR/workspace"

mkdir -p "$RUNNER_TEMP_DIR" "$WORKSPACE_DIR"

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

if [[ "${1:-}" == "validate" && "${2:-}" == "--file" ]]; then
  printf '%s\n' "${3:-}" >> "$NSYTE_VALIDATE_FILES"
  jq empty "${3:-}"
  exit $?
fi

printf '%s\n' "$@" > "$NSYTE_CAPTURE_ARGS"
exit "${NSYTE_FAKE_EXIT:-0}"
FAKE
chmod +x "$FAKE_NSYTE"

run_step() {
  : > "$CAPTURE_ARGS"
  : > "$VALIDATE_FILES"
  : > "$GITHUB_OUTPUT_FILE"
  local default_relays=$'wss://relay.damus.io\nwss://nos.lol\nwss://relay.nsite.lol\nwss://relay.nosto.re/\nwss://nsite.run'
  local default_servers=$'https://cdn.hzrd149.com/\nhttps://cdn.sovbit.host\nhttps://nostr.download \nhttps://nsite.run\nhttps://blssm.us'
  NSYTE_PATH="$FAKE_NSYTE" \
  NSYTE_VERSION="v0.27.0" \
  INPUT_SEC="${TEST_INPUT_SEC-}" \
  INPUT_NBUNKSEC="${TEST_INPUT_NBUNKSEC-nbunksec1testcredential}" \
  INPUT_DIRECTORY="${TEST_INPUT_DIRECTORY-./dist}" \
  INPUT_RELAYS="${TEST_INPUT_RELAYS-$default_relays}" \
  INPUT_SERVERS="${TEST_INPUT_SERVERS-$default_servers}" \
  INPUT_NAME="${TEST_INPUT_NAME-blog}" \
  INPUT_TITLE="${TEST_INPUT_TITLE-}" \
  INPUT_DESCRIPTION="${TEST_INPUT_DESCRIPTION-}" \
  INPUT_CONFIG_PATH="${TEST_INPUT_CONFIG_PATH-}" \
  INPUT_FORCE="${TEST_INPUT_FORCE-false}" \
  INPUT_SYNC="${TEST_INPUT_SYNC-false}" \
  INPUT_VERBOSE="${TEST_INPUT_VERBOSE-false}" \
  INPUT_FALLBACK="${TEST_INPUT_FALLBACK-}" \
  INPUT_CONCURRENCY="${TEST_INPUT_CONCURRENCY-4}" \
  INPUT_PUBLISH_SERVER_LIST="${TEST_INPUT_PUBLISH_SERVER_LIST-false}" \
  INPUT_PUBLISH_RELAY_LIST="${TEST_INPUT_PUBLISH_RELAY_LIST-false}" \
  INPUT_PUBLISH_PROFILE="${TEST_INPUT_PUBLISH_PROFILE-false}" \
  INPUT_USE_FALLBACK_RELAYS="${TEST_INPUT_USE_FALLBACK_RELAYS-false}" \
  INPUT_USE_FALLBACK_SERVERS="${TEST_INPUT_USE_FALLBACK_SERVERS-false}" \
  INPUT_PUBLISH_APP_HANDLER="${TEST_INPUT_PUBLISH_APP_HANDLER-false}" \
  INPUT_HANDLER_KINDS="${TEST_INPUT_HANDLER_KINDS-}" \
  INPUT_SKIP_SECRETS_SCAN="${TEST_INPUT_SKIP_SECRETS_SCAN-true}" \
  INPUT_SCAN_LEVEL="${TEST_INPUT_SCAN_LEVEL-}" \
  NSYTE_CAPTURE_ARGS="$CAPTURE_ARGS" \
  NSYTE_VALIDATE_FILES="$VALIDATE_FILES" \
  GITHUB_OUTPUT="$GITHUB_OUTPUT_FILE" \
  GITHUB_WORKSPACE="${TEST_GITHUB_WORKSPACE-$WORKSPACE_DIR}" \
  RUNNER_TEMP="$RUNNER_TEMP_DIR" \
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

echo "Checking direct title and description config generation..."
TEST_INPUT_TITLE="Example Site" \
TEST_INPUT_DESCRIPTION="A NIP-5A example site" \
run_step > "$TMP_DIR/metadata.log"

CONFIG_PATH=$(awk 'prev == "--config" { print; exit } { prev = $0 }' "$CAPTURE_ARGS")
if [[ -z "$CONFIG_PATH" || ! -f "$CONFIG_PATH" ]]; then
  echo "Direct title/description inputs did not create a deploy config."
  exit 1
fi
if ! grep -qxF "$CONFIG_PATH" "$VALIDATE_FILES"; then
  echo "Generated config was not validated before deploy."
  exit 1
fi
if ! jq -e '
  .title == "Example Site" and
  .description == "A NIP-5A example site" and
  .id == "blog" and
  .relays == [
    "wss://relay.damus.io",
    "wss://nos.lol",
    "wss://relay.nsite.lol",
    "wss://relay.nosto.re/",
    "wss://nsite.run"
  ] and
  .servers == [
    "https://cdn.hzrd149.com/",
    "https://cdn.sovbit.host",
    "https://nostr.download",
    "https://nsite.run",
    "https://blssm.us"
  ]
' "$CONFIG_PATH" > /dev/null; then
  echo "Generated config did not include expected metadata and deploy settings."
  jq . "$CONFIG_PATH"
  exit 1
fi
if ! awk 'NR == 1 { ok = ($0 == "--config") } NR == 3 { ok = ok && ($0 == "deploy") } END { exit ok ? 0 : 1 }' "$CAPTURE_ARGS"; then
  echo "Generated config was not passed as a global nsyte --config argument."
  exit 1
fi

echo "Checking config_path without individual deploy configuration inputs..."
cat > "$WORKSPACE_DIR/nsyte.config.json" <<'JSON'
{
  "relays": ["wss://relay.config.example"],
  "servers": ["https://server.config.example"],
  "id": "config-site",
  "title": "Configured Site",
  "description": "Loaded from config_path"
}
JSON

TEST_INPUT_CONFIG_PATH="nsyte.config.json" \
TEST_INPUT_RELAYS="" \
TEST_INPUT_SERVERS="" \
TEST_INPUT_NAME="" \
TEST_INPUT_TITLE="" \
TEST_INPUT_DESCRIPTION="" \
run_step > "$TMP_DIR/config-path.log"

EXPECTED_CONFIG_PATH="$WORKSPACE_DIR/nsyte.config.json"
if ! grep -qxF "$EXPECTED_CONFIG_PATH" "$VALIDATE_FILES"; then
  echo "config_path file was not validated before deploy."
  exit 1
fi
if ! awk -v config="$EXPECTED_CONFIG_PATH" '
  NR == 1 { ok = ($0 == "--config") }
  NR == 2 { ok = ok && ($0 == config) }
  NR == 3 { ok = ok && ($0 == "deploy") }
  END { exit ok ? 0 : 1 }
' "$CAPTURE_ARGS"; then
  echo "config_path was not passed to nsyte as a global --config argument."
  exit 1
fi
if grep -qx -- '--relays' "$CAPTURE_ARGS" || grep -qx -- '--servers' "$CAPTURE_ARGS" || grep -qx -- '--name' "$CAPTURE_ARGS"; then
  echo "config_path-only deploy unexpectedly added individual relays, servers, or name flags."
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
