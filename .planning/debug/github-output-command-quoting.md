---
status: fixed
trigger: "$gsd-debug getting this error from nsite-action@v0.4.0: generated GitHub shell reports a server-list fragment as No such file or directory, then the action prints a blank masked command, COMMAND_EXIT_CODE=0, and nsyte deploy completed successfully."
created: 2026-06-09T20:03:19+02:00
updated: 2026-06-09T20:09:10+02:00
---

# Debug Session: github-output-command-quoting

## Symptoms

### Expected behavior
The action should execute `nsyte deploy` with multiline relay and Blossom server inputs converted to comma-separated CLI values, and it should fail the workflow if command construction or deploy execution fails.

### Actual behavior
The generated GitHub Actions shell script tries to execute a command fragment from the server list:
`/home/runner/work/_temp/7184d3a1-89fd-4d12-94f4-8ad18297ff48.sh: line 2: ,https://nsite.run,https://blssm.us --concurrency 4 --skip-secrets-scan: No such file or directory`

The action then logs a blank masked command, `COMMAND_EXIT_CODE=0`, and `nsyte deploy completed successfully.`

### Error messages
`line 2: ,https://nsite.run,https://blssm.us --concurrency 4 --skip-secrets-scan: No such file or directory`

### Timeline
Observed in a GitHub Actions workflow using `sandwichfarm/nsite-action@v0.4.0` with `version: latest`.

### Reproduction
Use the action with multiline `relays` and `servers`, including:
`https://nostr.download `
`https://nsite.run`
`https://blssm.us`

## Current Focus

- hypothesis: The action passes a quoted deploy command through `$GITHUB_OUTPUT`, then injects it into `NSYT_COMMAND="${{ steps.build_cmd.outputs.command }}"`; the embedded quotes break the generated shell assignment, `set +e` ignores the shell error, and an empty `eval` returns success.
- test: Simulate GitHub expression interpolation with a quoted command output and multiline-derived server CSV; then replace command-string/eval execution with a Bash argument array and verify the malformed assignment path disappears.
- expecting: The simulation reproduces a command-fragment execution attempt or blank command, while the array-based implementation preserves each argument and propagates nonzero deploy exits.
- next_action: complete
- reasoning_checkpoint:
- tdd_checkpoint:

## Evidence

- timestamp: 2026-06-09T20:03:19+02:00
  observation: `action.yml` writes `command=${CMD}` to `$GITHUB_OUTPUT`, where `CMD` contains literal double quotes around executable path, directory, sec, relays, and servers.
- timestamp: 2026-06-09T20:03:19+02:00
  observation: `Run nsyte deploy` assigns `NSYT_COMMAND="${{ steps.build_cmd.outputs.command }}"` and executes `eval "$NSYT_COMMAND"` under `set +e`.
- timestamp: 2026-06-09T20:09:00+02:00
  observation: Local regression harness extracts the `Run nsyte deploy` step from `action.yml`, feeds it multiline relays/servers with a trailing-space server entry, and verifies the fake `nsyte` receives one normalized `--servers` argv value.
- timestamp: 2026-06-09T20:09:00+02:00
  observation: The same harness makes fake `nsyte` exit 23 and verifies the action step records `status=failure` and `exit_code=23`.

## Eliminated

## Resolution

- root_cause: A quoted command string was serialized through `$GITHUB_OUTPUT`, then interpolated into `NSYT_COMMAND="..."`. The embedded quotes broke the generated shell assignment, causing the shell to try to execute a server-list fragment; because `set +e` was active, an empty later `eval` returned 0 and produced a false success.
- fix: Build the deploy invocation as a Bash argument array in the `Run nsyte deploy` step, pass action inputs through step environment variables, normalize multiline relay/server inputs without command-string transport, print a masked argv, and execute `"${CMD[@]}"` directly.
- verification: `./scripts/test-command-build.sh`; `make test-local`.
- files_changed: `action.yml`, `scripts/test-command-build.sh`, `scripts/test-local.sh`, `Makefile`, `VERSION`, `README.md`
