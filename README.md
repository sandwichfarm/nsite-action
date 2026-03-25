# nsite-action

<!-- [![GitHub release (latest by date)](https://img.shields.io/github/v/release/your-username/nsite-action)](https://github.com/your-username/nsite-action/releases)
[![GitHub Actions CI](https://github.com/your-username/nsite-action/actions/workflows/test.yml/badge.svg)](https://github.com/your-username/nsite-action/actions/workflows/test.yml) -->

Deploy static websites to Blossom/Nostr in a GitHub Actions workflow, powered by [nsyte](https://github.com/sandwichfarm/nsyte).

## Dependencies
- Bunker Signer (NIP-46) for establishing a handshake
- [nsyte](https://github.com/sandwichfarm/nsyte) - For generating a signing credential with `nsyte ci`.

## Quick Start

1. **Setup nsyte locally** (one-time):
   ```bash
   nsyte ci
   ```
   Follow the Nostr Connect prompts and `nsyte` will display a signing credential such as `nbunksec`; it is revocable, but still treat it as a secret.

2. **Add GitHub Secret**:
   - Add the generated credential as a repository secret, for example `NBUNK_SECRET`

3. **Add to workflow**:
    ```yaml
    - name: Deploy to Nostr/Blossom
      uses: sandwichfarm/nsite-action@v0.2.2
      with:
        sec: ${{ secrets.NBUNK_SECRET }}
        directory: './dist'  # Your built website directory
        version: 'v0.23.0'
        relays: |
          wss://relay.nsite.lol
        servers: |
         https://cdn.hzrd149.com
         https://cdn.sovbit.host
   ```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `version` | No | `latest` | nsyte release tag to download (for example `v0.23.0`) |
| `sec` | No | - | Signing secret; accepts `nsec`, `nbunksec`, `bunker://` URL, or hex |
| `nbunksec` | No | - | Deprecated alias for `sec` |
| `directory` | Yes | - | Directory containing website files |
| `relays` | No | `''` | Newline-separated relay URIs |
| `servers` | No | `''` | Newline-separated Blossom server URIs |
| `force` | No | false | Re-upload all files |
| `purge` | No | false | Deprecated; no longer supported by `nsyte` |
| `sync` | No | false | Check all servers and upload missing blobs |
| `verbose` | No | false | Show detailed output |
| `concurrency` | No | 4 | Number of parallel uploads |
| `fallback` | No | '' | Fallback HTML path (e.g., "/index.html") |
| `publish_server_list` | No | false | Publish configured servers for fresh identities |
| `publish_relay_list` | No | false | Publish configured relays for fresh identities |
| `publish_profile` | No | false | Publish profile metadata for fresh identities |
| `use_fallback_relays` | No | false | Include nsyte default relays in addition to configured relays |
| `use_fallback_servers` | No | false | Include nsyte default servers in addition to configured servers |
| `publish_app_handler` | No | false | Publish a NIP-89 app handler announcement |
| `handler_kinds` | No | `''` | Comma-separated event kinds for the app handler |

## Outputs

| Output | Description |
|--------|-------------|
| `status` | Upload status (`success` or `failure`) |
| `nsyte_version_used` | Version of nsyte used |

## Features

- Downloads nsyte binary automatically
- Supports Linux, macOS, and Windows
- Masks sensitive secrets in logs
- Accepts `sec` directly and keeps `nbunksec` as a deprecated alias

## Credential Revocation

- Revocation is handled by your bunker signer of choice (NIP-46).
- If you leak your signing credential, rotate it immediately.
- Rotate credentials periodically: revoke the old credential, establish a new connection, and update your GitHub secret.

## Security Notes

- **DO NOT** commit signing credentials to source code
- Store the credential as a GitHub Secret
- Configure bunker with minimal permissions
- Consider pinning to a specific `version`
- Rotate credentials periodically

## Resources
- [awesome-nsite](https://github.com/nostrver-se/awesome-nsite)
- [nsite.run](https://nsite.run)
- [blossomservers.com](https://blossomservers.com)

## Development

See [test.yml](.github/workflows/test.yml) for testing. Run `make test-local` for local testing.

## License

[MIT License](./LICENSE) 
