#!/bin/bash

# This script fixes framework loading issues in Itsycal by:
# 1. Copying the frameworks from source to the app bundle
# 2. Code signing them with ad-hoc signing

echo "=== Itsycal Framework Fixer ==="

# Get the path to the app bundle
BUILT_PRODUCTS_DIR="$1"
if [ -z "$BUILT_PRODUCTS_DIR" ]; then
  echo "Usage: $0 <path_to_app_bundle>"
  echo "Example: $0 /Users/james/src/apps/Itsycal-gcieivfylwxvsefplkcfxzdcsxhr/Build/Products/Debug"
  exit 1
fi

APP_BUNDLE="${BUILT_PRODUCTS_DIR}/Itsycal.app"
FRAMEWORKS_FOLDER_PATH="Contents/Frameworks"
APP_FRAMEWORKS="${APP_BUNDLE}/${FRAMEWORKS_FOLDER_PATH}"
SOURCE_FRAMEWORKS="/Users/james/src/Itsycal/Itsycal/_frameworks"

echo "App bundle: ${APP_BUNDLE}"
echo "Source frameworks: ${SOURCE_FRAMEWORKS}"

# Check if the app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
  echo "Error: App bundle not found at $APP_BUNDLE"
  exit 1
fi

# Check if source frameworks folder exists
if [ ! -d "$SOURCE_FRAMEWORKS" ]; then
  echo "Error: Source frameworks folder not found at $SOURCE_FRAMEWORKS"
  exit 1
fi

# Create frameworks folder if it doesn't exist
mkdir -p "$APP_FRAMEWORKS"

# Function to process each framework
process_framework() {
  local framework_name="$1"
  echo "---------------------------------"
  echo "Processing $framework_name.framework"
  
  # Check if source framework exists
  if [ ! -d "${SOURCE_FRAMEWORKS}/${framework_name}.framework" ]; then
    echo "Error: Source framework ${framework_name}.framework not found"
    return 1
  fi
  
  # Remove existing framework if it exists
  if [ -d "${APP_FRAMEWORKS}/${framework_name}.framework" ]; then
    echo "Removing existing ${framework_name}.framework"
    rm -rf "${APP_FRAMEWORKS}/${framework_name}.framework"
  fi
  
  # Copy the framework from source
  echo "Copying ${framework_name}.framework from source"
  cp -R "${SOURCE_FRAMEWORKS}/${framework_name}.framework" "${APP_FRAMEWORKS}/"
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to copy ${framework_name}.framework"
    return 1
  fi
  
  # Fix permissions
  echo "Fixing permissions"
  chmod -R 755 "${APP_FRAMEWORKS}/${framework_name}.framework"
  
  # Ad-hoc code signing
  echo "Ad-hoc code signing ${framework_name}.framework"
  
  # If it's Sparkle, sign the AutoUpdate.app first
  if [ "$framework_name" == "Sparkle" ] && [ -d "${APP_FRAMEWORKS}/${framework_name}.framework/Versions/A/Resources/AutoUpdate.app" ]; then
    echo "Signing AutoUpdate.app in Sparkle framework"
    codesign --verbose --force --deep -o runtime --sign "-" "${APP_FRAMEWORKS}/${framework_name}.framework/Versions/A/Resources/AutoUpdate.app"
  fi
  
  # Sign the framework
  codesign --verbose --force -o runtime --sign "-" "${APP_FRAMEWORKS}/${framework_name}.framework/Versions/A"
  
  if [ $? -eq 0 ]; then
    echo "${framework_name}.framework successfully processed"
    return 0
  else
    echo "Error: Failed to code sign ${framework_name}.framework"
    return 1
  fi
}

# Process each framework
echo "Processing frameworks..."
process_framework "MASShortcut"
process_framework "Sparkle"

echo "---------------------------------"
echo "All frameworks processed. Itsycal should now run without dyld errors."
echo "Try running the app again."