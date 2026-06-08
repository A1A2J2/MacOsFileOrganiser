#!/bin/bash
set -e

APP_NAME="FileOrganizer"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

# Create App bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/"

# Compile Swift files
swiftc -o "$MACOS_DIR/$APP_NAME" \
    Sources/main.swift \
    Sources/AppDelegate.swift \
    Sources/StatusBarController.swift \
    Sources/SettingsWindowController.swift \
    Sources/InfoWindowController.swift \
    Sources/FileOrganizer.swift \
    Sources/HistoryManager.swift \
    Sources/ShortcutManager.swift \
    Sources/FolderMonitor.swift

echo "Build successful! App bundle created at $APP_BUNDLE"
