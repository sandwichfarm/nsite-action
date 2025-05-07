.PHONY: all help test-local tag release clean

# Default target - shows help
all: help

# Help message
help:
	@echo "nsite-action Makefile"
	@echo "Available targets:"
	@echo "  make test-local  - Run the local test script"
	@echo "  make tag         - Create a git tag from VERSION file"
	@echo "  make release     - Create a GitHub release from the latest tag"
	@echo "  make clean       - Clean up temporary test files"
	@echo "  make help        - Show this help message"

# Run the local test script
test-local:
	@echo "Running local test script..."
	./scripts/test-local.sh

# Tag a new version
tag:
	@echo "Tagging version from VERSION file..."
	./scripts/tag.sh

# Create a GitHub release
release:
	@echo "Creating GitHub release from the latest tag..."
	./scripts/release.sh

# Clean up test directories and files created by tests
clean:
	@echo "Cleaning up test files..."
	rm -rf test-local-dir
	rm -rf test-dist
	rm -f nsyte nsyte.exe *.zip *.tar.gz
	@echo "Clean complete."
