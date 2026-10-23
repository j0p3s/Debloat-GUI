# Changelog

All notable changes to this project are listed here, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [2.1.1] - 2026-10-23

### Fixed
- **The log box now follows the language.** Changing the language used to translate the whole window except the log at the bottom, which stayed in the language of the start. The introduction and every line written during a removal (progress, restore point, errors, summary) are now drawn again in the new language.

### Changed
- The version number is now in the file header (the first lines of the script), in the file name (`Debloat_Gui_v2.1.1.cmd`), in the window title, the README and this file.

## [2.1.0] - 2026-10-23

### Added
- **Four languages:** English, Português, Français and Español. A selector at the top right of the window changes the whole interface: buttons, columns, mode descriptions, app names and descriptions, dialogs and the log. The first run uses the Windows display language (English if it is not one of these) and the choice is saved in `%LOCALAPPDATA%\Debloat_GUI\language.txt`.
- **App status column:** every catalog app is listed as *Can be removed*, *Removed (date)* (removed earlier with this tool, read from its logs) or *Not installed* (not on this PC: removed by something else, or never installed).
- **Filter** above the lists: all apps, only those that can be removed, or only those already removed / not installed. The ticks in the Custom tab are kept when the filter changes.
- **Summary line** under each list with the number of apps in each state.
- Apps that cannot be removed are greyed out and cannot be ticked in the Custom tab.

### Changed
- The mode buttons and the **Remove** buttons count only the apps that can be removed.
- Logs are now written as `removed_YYYYMMDD_HHMMSS.txt`. Each removed app is recorded with its package names in brackets, which is what the lists use to recognize it in any language. Logs from 2.0.0 (`removidas_*.txt`) are still read.
- The restore point description follows the selected language.

## [2.0.0]

### Added
- Window with two tabs: **Modes** (Basic, Standard, Advanced, Ultra, each with its description and the exact list for this PC) and **Custom** (tick apps one by one, with buttons that tick everything up to a level).
- Catalog of known apps with four levels; each mode removes its own level and all the previous ones.
- Protection list: Microsoft Store, App Installer (winget), Windows Security, codecs, Notepad, Paint, Terminal, Snipping Tool and system components are never removed.
- Confirmation with the list before removing, optional restore point, and a log of the removed apps.
- Removal for every user and from the provisioning list, so apps are not installed again on new accounts; OneDrive is removed with its own uninstaller.
- Warning when the Xbox sign-in component is included.
- Administrator rights asked once (UAC); the console window is hidden.

[2.1.1]: ../../releases/tag/v2.1.1
[2.1.0]: ../../releases/tag/v2.1.0
[2.0.0]: ../../releases/tag/v2.0.0
