# nsite-action

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/your-username/nsite-action)](https://github.com/your-username/nsite-action/releases)
[![GitHub Actions CI](https://github.com/your-username/nsite-action/actions/workflows/test.yml/badge.svg)](https://github.com/your-username/nsite-action/actions/workflows/test.yml)

Deploy static websites to Blossom/Nostr using [nsyte](https://github.com/sandwichfarm/nsyte).

## Quick Start

_You will need to download/install [nsyte](http://github.com/sandwichfarm/nsyte) to generate an **nbunksec**_

1. **Setup nsyte locally** (one-time):
   ```bash
   nsyte ci
   ```

2. **Add GitHub Secret**:
   - Add the `nbunksec` string as a repository secret named `NBUNKSEC`

3. **Add to workflow**:
   ```yaml
   - name: Deploy to Nostr/Blossom
     uses: your-username/nsite-action@v1
     with:
       nbunksec: ${{ secrets.NBUNKSEC }}
       directory: './dist'  # Your built website directory
       relays: |
         wss://relay.damus.io
         wss://relay.snort.social
       servers: |
         wss://some.blossom.server.com
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

## Security Notes

- Store `nbunksec` as a GitHub Secret
- Configure bunker with minimal permissions
- Consider pinning to specific `nsyte_version`
- Rotate `nbunksec` periodically

## Development

See [test.yml](.github/workflows/test.yml) for testing. Run `make test-local` for local testing.

## License

[MIT License](./LICENSE) 
