# Using nsyte with nsite-action

[nsyte](https://github.com/sandwichfarm/nsyte) is the default deployment tool for nsite-action and offers the most features, including support for NIP-46 bunker authentication.

## Features

- **Binary distribution** - Fast execution, no npm dependencies
- **Bunker support** - Secure authentication via NIP-46
- **Private key support** - Alternative authentication method
- **Advanced options** - Force upload, purge, concurrency control, and more

## Configuration

### Basic Usage with Bunker (Recommended)

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nsyte  # Optional, nsyte is the default
    nbunksec: ${{ secrets.NBUNKSEC }}
    directory: ./dist
    relays: |
      wss://relay.damus.io
      wss://nos.lol
    servers: |
      https://cdn.hzrd149.com
      https://blossom.primal.net
```

### Using Private Key

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nsyte
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
    directory: ./dist
    relays: |
      wss://relay.damus.io
      wss://nos.lol
    servers: |
      https://cdn.hzrd149.com
```

### Advanced Options

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nsyte
    version: v0.5.3  # Specific version (default: latest)
    nbunksec: ${{ secrets.NBUNKSEC }}
    directory: ./dist
    relays: |
      wss://relay.damus.io
      wss://nos.lol
    servers: |
      https://cdn.hzrd149.com
    force: true  # Re-upload all files
    purge: true  # Delete remote files not present locally
    verbose: true  # Show detailed output
    concurrency: 8  # Number of parallel uploads (default: 4)
    fallback: /index.html  # For single-page applications
    publish_server_list: true  # Publish server list to relays
    publish_relay_list: true  # Publish relay list to Blossom servers
    publish_profile: true  # Publish profile to relays
```

## Authentication

nsyte supports two authentication methods:

1. **NIP-46 Bunker (Recommended)**: Use `nbunksec` for secure, remote signing
2. **Private Key**: Use `private_key` for direct signing (less secure)

## Version Management

Examples:
- `version: latest` - Always use the latest release (default)
- `version: v0.5.3` - Pin to specific version
- `version: 0.5.3` - Also works

## Platform Support

nsyte provides pre-built binaries for:
- Linux
- macOS
- Windows

The action automatically detects the runner platform and downloads the appropriate binary.

## Complete Example

Here's a complete GitHub Actions workflow using nsyte:

```yaml
name: Deploy to nsite

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Build website
      run: npm run build
      
    - name: Deploy to nsite
      uses: sandwichfarm/nsite-action@v2
      with:
        tool: nsyte
        nbunksec: ${{ secrets.NBUNKSEC }}
        directory: ./dist
        relays: |
          wss://relay.damus.io
          wss://nos.lol
          wss://relay.nostr.band
        servers: |
          https://cdn.hzrd149.com
          https://blossom.primal.net
        verbose: true
        fallback: /index.html  # For SPAs
```

### Example with Version Pinning

```yaml
- name: Deploy to nsite (pinned version)
  uses: sandwichfarm/nsite-action@v2
  with:
    tool: nsyte
    version: v0.5.3  # Pin to specific version
    nbunksec: ${{ secrets.NBUNKSEC }}
    directory: ./public
    relays: |
      wss://relay.damus.io
    servers: |
      https://cdn.hzrd149.com
    force: true  # Force re-upload all files
```