# Using nsite-cli with nsite-action

[nsite-cli](https://github.com/flox1an/nsite-cli) is a deployment tool by flox1an that uses npx for easy installation.

## Features

- **NPX-based** - No installation required, runs directly via npx
- **Simple interface** - Straightforward upload command
- **Private key authentication** - Uses nsec format keys
- **Fallback support** - For single-page applications

## Configuration

### Basic Usage

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nsite-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}  # Required (nsec format)
    directory: ./dist
    relays: |
      wss://nos.lol
      wss://relay.primal.net
    servers: |
      https://cdn.satellite.earth
```

### With Fallback for SPAs

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nsite-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
    directory: ./build
    relays: |
      wss://nos.lol
      wss://relay.primal.net
    servers: |
      https://cdn.satellite.earth
    fallback: /index.html  # For single-page applications
```

## Authentication

nsite-cli **only supports private key authentication**:
- Private key must be in nsec format
- Store as a GitHub Secret for security
- No bunker/NIP-46 support

## Parameters Supported

nsite-cli supports these parameters from the action:
- `directory` - The directory to upload
- `private_key` - Nostr private key (nsec format)
- `relays` - Comma-separated list of relay URLs
- `servers` - Comma-separated list of Blossom server URLs
- `fallback` - Fallback HTML file for SPAs

**Note**: The following parameters are not supported by nsite-cli:
- `force`, `purge`, `verbose`, `concurrency`
- `publish_server_list`, `publish_relay_list`, `publish_profile`

## Environment Variables

nsite-cli also supports configuration via environment variables:
- `NOSTR_RELAYS`
- `BLOSSOM_SERVERS`
- `NOSTR_PRIVATE_KEY`

However, when using the action, pass values via the action inputs instead.

## Version Information

The action uses a pinned version of nsite-cli (currently `0.1.16`) to ensure stability and reproducibility. This version is automatically updated when the action is maintained.

## Complete Example

Here's a complete GitHub Actions workflow using nsite-cli:

```yaml
name: Deploy with nsite-cli

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
        tool: nsite-cli
        private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
        directory: ./dist
        relays: |
          wss://nos.lol
          wss://relay.primal.net
          wss://relay.damus.io
        servers: |
          https://cdn.satellite.earth
        fallback: /index.html  # For SPAs
```

### Minimal Example

```yaml
- name: Deploy static site
  uses: sandwichfarm/nsite-action@v2
  with:
    tool: nsite-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
    directory: ./public
    relays: |
      wss://relay.damus.io
    servers: |
      https://cdn.satellite.earth
```

## Security Considerations

⚠️ **Warning**: This tool requires storing your Nostr private key as a GitHub Secret, which is less secure than bunker authentication. For production deployments, consider using nsyte with bunker authentication instead.