# nsite-action

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/sandwichfarm/nsite-action)](https://github.com/sandwichfarm/nsite-action/releases)
[![GitHub Actions CI](https://github.com/sandwichfarm/nsite-action/actions/workflows/test.yml/badge.svg)](https://github.com/sandwichfarm/nsite-action/actions/workflows/test.yml)

Deploy static websites to Blossom/Nostr using nsite deployment tools. Supports multiple deployment tools from [nsite.run](https://nsite.run).

## Supported Tools

| Tool | Status | Version | Authentication | Documentation |
|------|--------|---------|----------------|---------------|
| [nsyte](https://github.com/sandwichfarm/nsyte) | **Stable** | latest | ✅ Bunker (NIP-46)<br>✅ Private Key | [Guide](docs/nsyte.md) |
| [nsite-cli](https://github.com/flox1an/nsite-cli) | 🧪 Experimental | 0.1.16 | ⚠️ Private Key Only | [Guide](docs/nsite-cli.md) |
| [nous-cli](https://gitlab.com/soapbox-pub/nous-cli) | 🧪 Experimental | 0.1.3 | ⚠️ Private Key Only* | [Guide](docs/nous-cli.md) |
| [nostr-deploy-cli](https://github.com/sepehr-safari/nostr-deploy-cli) | 🧪 Experimental | 0.7.6 | ⚠️ Private Key Only | [Guide](docs/nostr-deploy-cli.md) |

*nous-cli manages its own keys internally

**Note**: NPX tools use pinned versions to ensure stability. These versions are updated periodically as part of action maintenance.

> **⚠️ Security Warning**: Tools marked "Private Key Only" require your Nostr private key to be stored as a GitHub Secret. This is less secure than bunker authentication. Consider using nsyte with bunker authentication for production deployments.

> **🧪 Experimental**: Non-nsyte tools are experimental and may have limited feature support or compatibility issues.

## Quick Start (with nsyte)

1. **Setup nsyte locally** (one-time):
   ```bash
   nsyte ci
   ```

2. **Add GitHub Secret**:
   - Add the `nbunksec` string as a repository secret named `NBUNKSEC`

3. **Add to workflow**:
   ```yaml
   - name: Deploy to Nostr/Blossom
     uses: sandwichfarm/nsite-action@v2
     with:
       tool: nsyte  # Optional, nsyte is default
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
| `tool` | No | nsyte | Deployment tool to use: `nsyte`, `nsite-cli`, `nous-cli`, or `nostr-deploy-cli` |
| `nbunksec` | Conditional* | - | Bunker auth string for nsyte (store as GitHub Secret) |
| `private_key` | Conditional* | - | Nostr private key in nsec format (store as GitHub Secret) |
| `directory` | Yes | - | Directory containing website files |
| `relays` | Yes | - | Newline separated relay URIs |
| `servers` | Yes | - | Newline separated server URIs |
| `version` | No | latest | Tool version (only applies to nsyte) |
| `force` | No | false | Re-upload all files (nsyte/nous-cli only) |
| `purge` | No | false | Delete remote files not present locally (nsyte/nous-cli only) |
| `verbose` | No | false | Show detailed output (nsyte/nous-cli only) |
| `concurrency` | No | 4 | Number of parallel uploads (nsyte only) |
| `fallback` | No | '' | Fallback HTML path (nsyte/nsite-cli only) |
| `publish_server_list` | No | false | Publish server list to relays (nsyte only) |
| `publish_relay_list` | No | false | Publish relay list to Blossom servers (nsyte only) |
| `publish_profile` | No | false | Publish profile to relays (nsyte only) |

*Authentication requirements:
- **nsyte**: Requires either `nbunksec` or `private_key`
- **Other tools**: Require `private_key` only

## Outputs

| Output | Description |
|--------|-------------|
| `status` | Deployment status (`success` or `failure`) |
| `tool_used` | The deployment tool that was used |
| `tool_version_used` | Version of the tool used (for binary tools) |
| `nsyte_version_used` | Deprecated: Use `tool_version_used` |

## Features

- Supports multiple nsite deployment tools
- Downloads nsyte binary automatically
- Runs other tools via npx (no installation needed)
- Uses pinned versions for NPX tools to ensure stability
- Supports Linux, macOS, and Windows
- Masks sensitive secrets in logs
- Backward compatible (nsyte is default)

## Security Notes

- Store `nbunksec` as a GitHub Secret
- Configure bunker with minimal permissions
- Consider pinning to specific `nsyte_version`
- Rotate `nbunksec` periodically

## Development

See [test.yml](.github/workflows/test.yml) for testing. Run `make test-local` for local testing.

## License

[MIT License](./LICENSE) 
