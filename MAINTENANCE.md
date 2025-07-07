# Maintenance Guide

## Updating Tool Versions

All tool versions are centrally managed in `versions.json`:

```json
{
  "tools": {
    "nsyte": {
      "version": "v0.12.3",
      "type": "binary"
    },
    "nsite-cli": {
      "version": "0.1.16",
      "type": "npx"
    },
    "nous-cli": {
      "version": "0.1.3",
      "type": "npx",
      "package": "@soapbox.pub/nous"
    },
    "nostr-deploy-cli": {
      "version": "0.7.6",
      "type": "npx"
    }
  }
}
```

### To update a tool version:

1. Edit `versions.json` with the new version number
2. Run `./scripts/update-version-docs.sh` to update the README
3. Commit both changes

### Version Format Guidelines:

- **nsyte**: Use "v" prefix (e.g., "v0.12.4")
- **NPX tools**: Use bare version numbers (e.g., "0.1.17")

### Testing Version Updates:

After updating versions, test with:

```bash
# Test all tools
act -W .github/workflows/test.yml

# Test specific tool
act -W .github/workflows/test-feature.yml -e '{"inputs":{"tool":"nsite-cli"}}'
```

## Adding a New Tool

1. Add tool configuration to `versions.json`
2. Update action.yml validation and command building
3. Add documentation in `docs/<tool-name>.md`
4. Update README.md supported tools table
5. Add test cases in `.github/workflows/test.yml`