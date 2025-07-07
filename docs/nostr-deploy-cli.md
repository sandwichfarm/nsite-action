# Using nostr-deploy-cli with nsite-action

[nostr-deploy-cli](https://github.com/sepehr-safari/nostr-deploy-cli) is a deployment tool by sepehr-safari that provides subdomain-based deployments.

## Features

- **NPM/NPX support** - Can be run via npx or global install
- **Subdomain generation** - Creates npub-based subdomains
- **Auto-detection** - Automatically detects build directories
- **Configuration management** - Separate auth and config steps

## Configuration

### Basic Usage

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nostr-deploy-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}  # Required (nsec format)
    directory: ./dist
    relays: |
      wss://relay.damus.io
      wss://nos.lol
    servers: |
      https://blossom.example.com
```

### With Custom Build Directory

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nostr-deploy-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
    directory: ./build  # Specify build directory
    relays: |
      wss://relay.damus.io
      wss://nos.lol
      wss://relay.nostr.band
    servers: |
      https://blossom.example.com
```

## Authentication

nostr-deploy-cli **only supports private key authentication**:
- Private key must be in nsec format
- The action handles key import automatically via `nostr-deploy-cli auth -k`
- No bunker/NIP-46 support

## How It Works

The action runs these commands in sequence:
1. `npx nostr-deploy-cli auth -k <private_key>` - Imports your key
2. `npx nostr-deploy-cli config -r <relays>` - Sets relay configuration
3. `npx nostr-deploy-cli config -b <server>` - Sets Blossom server
4. `npx nostr-deploy-cli deploy -d <directory> --skip-setup` - Deploys the site

## Parameters Supported

nostr-deploy-cli supports these parameters from the action:
- `directory` - The build directory to deploy
- `private_key` - Nostr private key (nsec format)
- `relays` - List of Nostr relay URLs
- `servers` - Blossom server URL (only first server is used)

**Note**: The following parameters are not supported by nostr-deploy-cli:
- `force`, `purge`, `verbose`, `concurrency`, `fallback`
- `publish_server_list`, `publish_relay_list`, `publish_profile`

## Deployment Details

- Creates subdomains based on your npub (e.g., `npub1xxx.nostrdeploy.com`)
- Publishes file metadata as Nostr events (kind 34128)
- Supports React, Vue, Angular, and other static site frameworks
- Auto-detects common build directories if not specified

## Version Information

The action uses a pinned version of nostr-deploy-cli (currently `0.7.6`) to ensure stability and reproducibility. This version is automatically updated when the action is maintained.

## Complete Example

Here's a complete GitHub Actions workflow using nostr-deploy-cli:

```yaml
name: Deploy with nostr-deploy-cli

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
        tool: nostr-deploy-cli
        private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
        directory: ./dist
        relays: |
          wss://relay.damus.io
          wss://nos.lol
          wss://relay.nostr.band
        servers: |
          https://blossom.example.com
```

### Example with Auto-detected Build Directory

```yaml
- name: Deploy Vue.js app
  uses: sandwichfarm/nsite-action@v2
  with:
    tool: nostr-deploy-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
    directory: ./dist  # Auto-detects common directories if omitted
    relays: |
      wss://relay.damus.io
    servers: |
      https://blossom.example.com
```

### Multi-relay Configuration

```yaml
- name: Deploy with multiple relays
  uses: sandwichfarm/nsite-action@v2
  with:
    tool: nostr-deploy-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
    directory: ./build
    relays: |
      wss://relay.damus.io
      wss://nos.lol
      wss://relay.snort.social
      wss://relay.nostr.band
      wss://nostr.wine
    servers: |
      https://blossom.example.com
```

## Deployment URLs

After deployment, your site will be available at:
- `https://npub1xxx.nostrdeploy.com` (where npub1xxx is your public key)

The exact URL will depend on the domain configured in the tool.

## Security Considerations

⚠️ **Warning**: This tool requires storing your Nostr private key as a GitHub Secret, which is less secure than bunker authentication. For production deployments, consider:
1. Using nsyte with bunker authentication for better security
2. Rotating your private keys regularly
3. Using a dedicated key for deployments only

## Troubleshooting

If deployment fails:
1. Ensure your private key is in the correct nsec format
2. Verify the build directory path is correct
3. Check that at least one relay and one Blossom server are specified
4. Review the action logs for specific error messages