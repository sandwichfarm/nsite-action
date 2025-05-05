# nsite-action

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/your-username/nsite-action)](https://github.com/your-username/nsite-action/releases)
[![GitHub Actions CI](https://github.com/your-username/nsite-action/actions/workflows/test.yml/badge.svg)](https://github.com/your-username/nsite-action/actions/workflows/test.yml)

A GitHub Action to deploy static website files to Blossom/Nostr using the [nsyte](https://github.com/sandwichfarm/nsyte) tool.

This action simplifies the process of publishing decentralized websites by automating the `nsyte upload` command within your GitHub workflows.

## Features

*   Downloads the specified (or latest) `nsyte` binary release automatically.
*   Supports Linux, macOS, and Windows runners (x64 and ARM64 where available from `nsyte` releases).
*   Wraps the `nsyte upload` command, exposing common options as inputs.
*   Authenticates using the secure `nbunksec` string method (requires a NIP-46 bunker).
*   Masks the `nbunksec` secret in workflow logs.

## Prerequisites

1.  **nsyte Setup:** You need to have set up `nsyte` locally at least once to connect to a NIP-46 bunker.
    ```bash
    # Install nsyte (if not already installed)
    # See: https://github.com/sandwichfarm/nsyte#installation

    # Connect to your bunker (follow prompts or use flags)
    nsyte bunker connect 'bunker://...' 
    # or 
    # nsyte bunker connect --pubkey <pubkey> --relay <relay> --secret <secret>
    ```
2.  **Generate nbunksec:** Export the connection secret.
    ```bash
    nsyte bunker export
    # Copy the output starting with nbunksec...
    ```
3.  **Remove Local Secret (Recommended):** For maximum security, remove the connection from your local machine after exporting the `nbunksec`.
    ```bash
    nsyte bunker remove <bunker_pubkey>
    ```
4.  **GitHub Secret:** Add the copied `nbunksec` string as a repository or organization secret in GitHub (e.g., named `NBUNKSEC`).

## Usage

Add a step to your workflow file (e.g., `.github/workflows/deploy.yml`) that uses this action.

```yaml
name: Deploy Website to Nostr/Blossom

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      # Optional: Build your static site (e.g., with Node.js)
      # - name: Setup Node.js
      #   uses: actions/setup-node@v4
      #   with:
      #     node-version: '20'
      # - name: Install Dependencies
      #   run: npm ci
      # - name: Build Site
      #   run: npm run build # Assuming your build output is in 'dist'

      - name: Deploy with nsite-action
        # Replace 'your-username/nsite-action@v1' with the correct path
        # For testing within this repo: uses: ./
        uses: your-username/nsite-action@v1 
        id: nsite_deploy
        with:
          # Required: The nbunksec string from GitHub secrets
          nbunksec: ${{ secrets.NBUNKSEC }}

          # Required: Directory containing the built website files
          directory: './dist' # Adjust to your build output directory

          # Optional: Specify nsyte version (defaults to latest release)
          # nsyte_version: 'v0.3.6'

          # Optional: Corresponds to nsyte upload --force
          # force: true

          # Optional: Corresponds to nsyte upload --purge
          # purge: true

          # Optional: Corresponds to nsyte upload --verbose
          # verbose: true

          # Optional: Corresponds to nsyte upload --concurrency
          # concurrency: 8

          # Optional: Corresponds to nsyte upload --fallback (for SPAs)
          # fallback: '/index.html'

      # Optional: Check the output status
      - name: Check Deployment Status
        if: always() # Run even if the previous step failed
        run: |
          echo "nsite deployment status: ${{ steps.nsite_deploy.outputs.status }}"
          echo "nsyte version used: ${{ steps.nsite_deploy.outputs.nsyte_version_used }}"
          if [[ "${{ steps.nsite_deploy.outputs.status }}" != "success" ]]; then
            echo "Deployment failed!"
            exit 1
          fi
```

## Inputs

| Input           | Description                                                                                                   | Required | Default  |
| --------------- | ------------------------------------------------------------------------------------------------------------- | -------- | -------- |
| `nsyte_version` | The version tag of `nsyte` to use (e.g., "v0.3.6"). Must exist in `sandwichfarm/nsyte` releases.             | `false`  | `latest` |
| `nbunksec`      | The `nbunksec` string for authentication via NIP-46 bunker. **Store this as a GitHub Secret.**                | `true`   |          |
| `directory`     | The directory containing the static files to upload.                                                          | `true`   |          |
| `force`         | Corresponds to the `--force` flag in `nsyte upload`. Re-upload all files.                                     | `false`  | `false`  |
| `purge`         | Corresponds to the `--purge` flag in `nsyte upload`. Delete remote files not present locally.                 | `false`  | `false`  |
| `verbose`       | Corresponds to the `--verbose` flag in `nsyte upload`. Show detailed output.                                  | `false`  | `false`  |
| `concurrency`   | Corresponds to the `--concurrency` flag in `nsyte upload`. Number of parallel uploads.                      | `false`  | `4`      |
| `fallback`      | Corresponds to the `--fallback` flag in `nsyte upload`. Path to the fallback HTML file (e.g., `/index.html`). | `false`  | `''`     |

## Outputs

| Output               | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `status`             | Status of the upload operation (`success` or `failure`).                  |
| `nsyte_version_used` | The actual version tag of `nsyte` that was downloaded and used by the run. |

## Security

*   **`nbunksec` Secret:** The `nbunksec` string contains sensitive cryptographic material derived from your bunker connection secret. **NEVER** commit it directly to your repository. Always store it as a [GitHub Encrypted Secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets).
*   **Bunker Permissions:** It is highly recommended to configure your NIP-46 bunker to grant minimal necessary permissions for the key associated with your CI/CD `nbunksec`. Ideally, restrict it to only allow publishing the specific event kinds `nsyte` uses (primarily `kind:34128` website events and potentially profile/relay list events if configured in `nsyte.json`).
*   **Secret Rotation:** Periodically generate a new `nbunksec` string, update the GitHub secret, and revoke the old connection in your bunker.
*   **Binary Trust:** This action downloads pre-compiled binaries from the `sandwichfarm/nsyte` releases. Ensure you trust the source of these binaries. Pinning to a specific `nsyte_version` is recommended over `latest` for production workflows to prevent unexpected changes.

## Development & Testing

This repository contains a test workflow (`.github/workflows/test.yml`) that runs on pushes/PRs to validate the action's core logic (binary download, command construction).

To test locally:

1.  You might need tools like `act` (though composite actions can have limitations).
2.  Push changes to a branch and observe the test workflow run in GitHub Actions.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

[MIT License](./LICENSE) (To be added) 