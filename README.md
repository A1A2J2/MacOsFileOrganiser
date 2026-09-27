# File Organizer

File Organizer is a lightweight, customizable macOS menu bar application designed to automatically sort and manage your files. It continuously monitors a designated source folder (e.g., your Downloads or Desktop) and organizes incoming files into subfolders based on their extensions.

## Features

- **Automatic File Sorting**: Automatically moves files from a source folder to categorized subfolders in an output directory based on their file types (e.g., Images, Documents, Videos, Archives).
- **Unobtrusive Menu Bar App**: Runs quietly in the background and is easily accessible from your macOS menu bar.
- **Customizable Scanning**: Configure intervals for automatic scanning or manually trigger an organization pass.
- **History & Revert**: Accidentally organized a file you needed where it was? The history feature allows you to instantly revert a recent file organization event, returning files to their original locations.
- **Custom Scripts**: Supports executing custom bash commands after a scan completes.
- **Exclusion Lists**: Specify file extensions that should be ignored by the organizer.
- **Global Hotkeys**: Configure custom global shortcuts for instant organization, opening the output folder, reverting history, and more.

## Installation & Setup

1. **Download the DMG**: Download the latest release from the Releases page.
2. **Install**: Open the `.dmg` file and drag the `FileOrganizer` app to your `Applications` folder.
3. **Run**: Launch `FileOrganizer` from your Applications folder. You will see a new folder icon in your menu bar.
4. **Configure**: Click the menu bar icon and select **Settings...** to set up your Source Folder (the folder to watch) and Output Folder (where sorted files will go).

## Building from Source

To compile the application yourself:

```bash
cd FileOrganizer
./build.sh
```

To create a distributable DMG file:

```bash
./create_dmg.sh
```

## Disclaimer

This software is provided "as-is", without any express or implied warranty. In no event shall the authors be held liable for any damages arising from the use of this software. We hold no responsibility for any lost, corrupted, or misplaced files. Please ensure you have adequate backups of your data before utilizing automated file organization features.

## License

© 2026 A1A2J2. All rights reserved.
