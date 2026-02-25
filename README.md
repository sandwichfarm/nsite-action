# nsite-action

<!-- [![GitHub release (latest by date)](https://img.shields.io/github/v/release/your-username/nsite-action)](https://github.com/your-username/nsite-action/releases)
[![GitHub Actions CI](https://github.com/your-username/nsite-action/actions/workflows/test.yml/badge.svg)](https://github.com/your-username/nsite-action/actions/workflows/test.yml) -->

Deploy static websites to Blossom/Nostr in a Github Actions Workflow, powered by [nsyte](https://github.com/sandwichfarm/nsyte).

## Dependencies
- Bunker Signer (NIP-46) for establishing a handshake
- [nsyte](http://github.com/sandwichfarm/nsyte) - For generating an `nbunksec` bunker secret key.

## Quick Start

1. **Setup nsyte locally** (one-time):
   ```bash
   nsyte ci
   ```
   Follow prompts for Nostr Connect and it will display an **nbunksec**; this is a revocable credential, but still treat it as a secret.

2. **Add GitHub Secret**:
   - Add the `nbunksec` string as a repository secret named `NBUNKSEC`

3. **Add to workflow**:
   ```yaml
   - name: Deploy to Nostr/Blossom
     uses: sandwichfarm/nsite-action@v0.2.2
     with:
       nbunksec: ${{ secrets.NBUNKSEC }}
       directory: './dist'  # Your built website directory
       relays: |
         wss://relay.nsite.lol
       servers: |
         https://cdn.hzrd149.com
         https://cdn.sovbit.host
   ```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `nbunksec` | Yes | - | Bunker auth string (store as GitHub Secret) |
| `directory` | Yes | - | Directory containing website files |
| `relays` | Yes | - | Newline separated relay URIs |
| `servers` | Yes | - | Newline separated server URIs |
| `nsyte_version` | No | latest | Version tag (e.g., "v0.5.0") |
| `force` | No | false | Re-upload all files |
| `purge` | No | false | Delete remote files not present locally |
| `verbose` | No | false | Show detailed output |
| `concurrency` | No | 4 | Number of parallel uploads |
| `fallback` | No | '' | Fallback HTML path (e.g., "/index.html") |
| `publish_server_list` | No | false | use this for new/fresh npubs without blossom servers configured |
| `publish_relay_list` | No | false | use this for new/fresh npubs without relays configured |
| `publish_profile` | No | false | use this for new/fresh npubs without a profile configured |

## Outputs

| Output | Description |
|--------|-------------|
| `status` | Upload status (`success` or `failure`) |
| `nsyte_version_used` | Version of nsyte used |

## Features

- Downloads nsyte binary automatically
- Supports Linux, macOS, and Windows
- Masks sensitive secrets in logs
- Authenticates via NIP-46 bunker

## `nbunksec` Revocation

- Revocation is handled by your Bunker Signer of choice (NIP-46).
- If you leak your `nbunksec` you should rotate your keys.
- keys should be rotated periodically (revoke old `nbunksec`, establish a new connection and update secrets)

## Security Notes

- **DO NOT** store `nbunksec` as an environment variable or commit to source code
- Store `nbunksec` as a GitHub Secret
- Configure bunker with minimal permissions
- Consider pinning to specific `nsyte_version`
- Rotate `nbunksec` periodically

## Resources
- [awesome-nsite](https://github.com/nostrver-se/awesome-nsite)
- [nsite.run](https://nsite.run)
- [blossomservers.com](https://blossomservers.com)

## Development

See [test.yml](.github/workflows/test.yml) for testing. Run `make test-local` for local testing.

## License

[MIT License](./LICENSE) 
