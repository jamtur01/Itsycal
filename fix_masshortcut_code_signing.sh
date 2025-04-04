#!/bin/bash

# This script adds code signing for MASShortcut.framework
# to fix the dyld error: Library not loaded: @rpath/MASShortcut.framework/Versions/A/MASShortcut

echo "Fixing code signing for MASShortcut.framework..."

# Get the path to the app bundle
BUILT_PRODUCTS_DIR="$1"
if [ -z "$BUILT_PRODUCTS_DIR" ]; then
  echo "Usage: $0 <path_to_app_bundle>"
  echo "Example: $0 /Users/james/src/apps/Itsycal-gcieivfylwxvsefplkcfxzdcsxhr/Build/Products/Debug"
  exit 1
fi

FRAMEWORKS_FOLDER_PATH="Itsycal.app/Contents/Frameworks"
LOCATION="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# Check if the frameworks folder exists
if [ ! -d "$LOCATION" ]; then
  echo "Error: Frameworks folder not found at $LOCATION"
  exit 1
fi

# Check if MASShortcut.framework exists
if [ ! -d "$LOCATION/MASShortcut.framework" ]; then
  echo "Error: MASShortcut.framework not found in $LOCATION"
  exit 1
fi

# Show available code signing identities
echo "Available code signing identities:"
security find-identity -v -p codesigning

# Use the "-" identity for ad-hoc signing which doesn't require a specific identity
echo "Using ad-hoc code signing (no specific identity)"
IDENTITY="-"

# Code sign the framework
echo "Code signing MASShortcut.framework with ad-hoc identity"
codesign --verbose --force -o runtime --sign "$IDENTITY" "$LOCATION/MASShortcut.framework/Versions/A"

if [ $? -eq 0 ]; then
  echo "Success! MASShortcut framework has been properly code signed."
  echo "You should now be able to run the app without the dyld error."
else
  echo "Error: Code signing failed."
  exit 1
fi