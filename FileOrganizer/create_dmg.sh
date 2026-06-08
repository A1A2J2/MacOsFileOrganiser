#!/bin/bash
set -e

APP_NAME="FileOrganizer"
APP_BUNDLE="FileOrganizer.app"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME} Installer"

# Remove existing DMG if it exists
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

echo "Creating DMG for $APP_NAME..."

# Create a temporary staging directory
STAGING_DIR=$(mktemp -d "/tmp/${APP_NAME}_DMG_XXXXXX")

# Copy the App bundle into the staging directory
cp -r "$APP_BUNDLE" "$STAGING_DIR/"

# Create a symlink to Applications folder in the staging directory
ln -s /Applications "$STAGING_DIR/Applications"

# Create the DMG using hdiutil
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# Clean up staging directory
rm -rf "$STAGING_DIR"

echo "DMG successfully created at $DMG_NAME"
