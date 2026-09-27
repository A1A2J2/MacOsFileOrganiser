#!/bin/bash
set -e

# Ensure create-dmg is installed before running
if ! command -v create-dmg &> /dev/null; then
    echo "Installing create-dmg utility..."
    brew install create-dmg
fi

echo "Building final DMG package seamlessly..."
rm -f "FileOrganizer.dmg"

create-dmg \
  --volname "FileOrganizer Installer" \
  --volicon "AppIcon.icns" \
  --background "bg.png" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "FileOrganizer.app" 160 200 \
  --app-drop-link 440 200 \
  "FileOrganizer.dmg" \
  "FileOrganizer.app"

echo "🎉 Success! Clean DMG built without annoying mount popups."
