#!/bin/bash

#
# Package Foundry VTT Module for Release
#
# This script packages your Foundry VTT module for distribution by:
# 1. Reading module.json to get module information
# 2. Validating the manifest and download URLs
# 3. Creating a ZIP archive with all necessary files
# 4. Copying files to the release directory
#
# Author: Christine Benedict
# Version: 1.0.0
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions for colored output
info() { echo -e "${CYAN}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
warning() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}"; }

# Configuration
RELEASE_DIR="release"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_JSON="$SCRIPT_DIR/module.json"

# Check if module.json exists
if [ ! -f "$MODULE_JSON" ]; then
    error "Error: module.json not found at: $MODULE_JSON"
    exit 1
fi

info "Reading module.json..."
MODULE_ID=$(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$MODULE_JSON" | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
MODULE_TITLE=$(grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' "$MODULE_JSON" | sed 's/.*"title"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
MODULE_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$MODULE_JSON" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

info "Module: $MODULE_TITLE"
info "ID: $MODULE_ID"
info "Version: $MODULE_VERSION"
echo ""

# Validate URLs
info "Validating URLs..."
EXPECTED_MANIFEST="https://github.com/imalane/$MODULE_ID/releases/latest/download/module.json"
EXPECTED_DOWNLOAD="https://github.com/imalane/$MODULE_ID/releases/latest/download/$MODULE_ID.zip"

CURRENT_MANIFEST=$(grep -o '"manifest"[[:space:]]*:[[:space:]]*"[^"]*"' "$MODULE_JSON" | sed 's/.*"manifest"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
CURRENT_DOWNLOAD=$(grep -o '"download"[[:space:]]*:[[:space:]]*"[^"]*"' "$MODULE_JSON" | sed 's/.*"download"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ "$CURRENT_MANIFEST" != "$EXPECTED_MANIFEST" ]; then
    warning "Manifest URL should be: $EXPECTED_MANIFEST"
    warning "Current: $CURRENT_MANIFEST"
fi

if [ "$CURRENT_DOWNLOAD" != "$EXPECTED_DOWNLOAD" ]; then
    warning "Download URL should be: $EXPECTED_DOWNLOAD"
    warning "Current: $CURRENT_DOWNLOAD"
fi
echo ""

# Prepare release directory
info "Preparing files for packaging..."
RELEASE_PATH="$SCRIPT_DIR/$RELEASE_DIR"
if [ -d "$RELEASE_PATH" ]; then
    rm -rf "$RELEASE_PATH"
fi
mkdir -p "$RELEASE_PATH"

# Create ZIP archive
ZIP_PATH="$RELEASE_PATH/$MODULE_ID.zip"
info "Creating ZIP archive: $MODULE_ID.zip"

# Create temporary directory for staging
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Files and folders to include
INCLUDE_ITEMS=("module.json" "README.md" "LICENSE" "scripts" "styles")

# Copy files to temp directory
for item in "${INCLUDE_ITEMS[@]}"; do
    SOURCE_PATH="$SCRIPT_DIR/$item"
    if [ -e "$SOURCE_PATH" ]; then
        cp -r "$SOURCE_PATH" "$TEMP_DIR/"
    fi
done

# Create ZIP from temp directory
cd "$TEMP_DIR"
zip -r "$ZIP_PATH" . > /dev/null

# Copy module.json to release directory
cp "$MODULE_JSON" "$RELEASE_PATH/module.json"

cd "$SCRIPT_DIR"

echo ""
success "Package created successfully!"
echo ""
info "Release files created in: ./$RELEASE_DIR"
info "  - module.json"
info "  - $MODULE_ID.zip"
echo ""

# Display package size
ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
info "Package size: $ZIP_SIZE"
echo ""

# Next steps
info "--- Next Steps ---"
info "1. Commit and push your changes to GitHub"
info "2. Create a new release at: https://github.com/imalane/$MODULE_ID/releases/new"
info "3. Tag the release as: v$MODULE_VERSION"
info "4. Upload both files from the 'release' directory:"
info "   - module.json"
info "   - $MODULE_ID.zip"
info "5. Publish the release"
echo ""
info "Manifest URL for Foundry: $EXPECTED_MANIFEST"
