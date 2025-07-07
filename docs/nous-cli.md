# Using nous-cli with nsite-action

[nous-cli](https://gitlab.com/soapbox-pub/nous-cli) is a deployment tool by Soapbox that manages its own cryptographic identities per project.

## Features

- **NPX-based** - Runs via `@soapbox.pub/nous`
- **Automatic key management** - Creates and stores keys per project
- **Simple deployment** - Minimal configuration required
- **SQLite storage** - Secure local key storage

## Configuration

### Basic Usage

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nous-cli
    directory: ./dist
    # Note: private_key is required by the action but ignored by nous-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}
```

### With Options

```yaml
- uses: nsite-action/action@v2
  with:
    tool: nous-cli
    directory: ./public
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}  # Required but ignored
    force: true  # Force republish all files
    purge: true  # Delete old file events first
    verbose: true  # Show detailed output
```

## Authentication

**Important**: nous-cli manages its own keys:
- Creates a unique keypair per project automatically
- Stores keys securely in a local SQLite database
- The `private_key` input is required by the action but **will be ignored** by nous-cli
- Each deployment uses the project's stored identity

## Parameters Supported

nous-cli supports these parameters from the action:
- `directory` - The directory to publish
- `force` - Forces republishing of all files
- `purge` - Deletes old file events before publishing
- `verbose` - Shows detailed output

**Note**: The following parameters are not supported by nous-cli:
- `relays`, `servers` - Uses its own configured defaults
- `fallback`, `concurrency`
- `publish_server_list`, `publish_relay_list`, `publish_profile`

## How It Works

1. On first run, nous-cli creates a new project identity
2. Keys are stored in a local SQLite database
3. Each subsequent deployment uses the same identity
4. The tool publishes to its configured network of relays and Blossom servers

## Limitations

- Cannot use external private keys
- Cannot configure relays/servers via action inputs
- Each GitHub runner may create a new identity (no persistence between runs)
- Best suited for projects that don't need specific key control

## Version Information

Examples:
- `version: latest` - Use the most recent version
- `version: 0.1.3` - Pin to specific version
- `version: v0.1.3` - Also works

## Complete Example

Here's a complete GitHub Actions workflow using nous-cli:

```yaml
name: Deploy with nous-cli

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
        tool: nous-cli
        private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}  # Required but ignored
        directory: ./dist
        verbose: true
```

### Example with Force and Purge

```yaml
- name: Deploy and clean old files
  uses: sandwichfarm/nsite-action@v2
  with:
    tool: nous-cli
    private_key: ${{ secrets.NOSTR_PRIVATE_KEY }}  # Required but ignored
    directory: ./public
    force: true    # Force republish all files
    purge: true    # Delete old file events first
    verbose: true  # Show detailed output
```

## Important Notes

1. **Key Management**: The `private_key` input is required by the action for compatibility, but nous-cli will ignore it and use its own managed keys.

2. **Stateless Runners**: Since GitHub Actions runners are stateless, nous-cli may create a new identity for each deployment. This means:
   - Your site may get a new npub with each deployment
   - Previous deployments may become orphaned
   - Consider using a tool that accepts external keys for consistent deployments

3. **Network Configuration**: You cannot configure which relays or servers nous-cli uses through the action. It uses its own preconfigured network.

## Security Considerations

While nous-cli manages its own keys securely, the lack of persistent key storage in GitHub Actions means you cannot maintain a consistent identity across deployments. For production use cases requiring consistent identity, consider using nsyte with bunker authentication.