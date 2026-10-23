# Debloat GUI

A single-file Windows app remover with a window. Pick a level (**Basic**, **Standard**, **Advanced** or **Ultra**) or tick apps one by one, see **what can be removed and what is already gone**, and remove them with a restore point and a log.

Available in **English, Português, Français and Español**. Free and open source.

![platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue) ![license](https://img.shields.io/badge/license-MIT-green)

- **No install.** One `.cmd` file that uses the Windows PowerShell 5.1 that comes with Windows. You can open it in a text editor and read it before running it.
- **Only a known list.** Nothing outside the built-in catalog is ever removed, and the Microsoft Store, App Installer (winget), Windows Security, codecs, Notepad, Paint, Terminal, Snipping Tool and system components are protected.
- **You see before it happens.** The list of apps and a confirmation come first; a restore point is created by default.

---

## Table of contents

- [Quick start](#quick-start)
- [What you see in the window](#what-you-see-in-the-window)
- [The four modes](#the-four-modes)
- [App status: removable, removed, not installed](#app-status-removable-removed-not-installed)
- [Languages](#languages)
- [Safety](#safety)
- [Logs and reinstalling apps](#logs-and-reinstalling-apps)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)
- [Contributing](#contributing)
- [Repository layout](#repository-layout)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Quick start

**Requirements:** Windows 10 or 11 and an account that can approve the administrator (UAC) prompt. Nothing else to install.

1. Download **`Debloat_Gui.cmd`** (from the [latest release](../../releases/latest) or the green **Code** button).
2. Double-click it and accept the administrator prompt. Removing apps for every user needs it, and it is asked once.
3. Wait a few seconds while the installed apps are scanned.
4. Choose a mode (or the **Custom** tab), check the list, click the red button and confirm.
5. Restart the PC when it finishes.

> If Windows SmartScreen blocks the file, click **More info > Run anyway**, or right-click the file > **Properties** > tick **Unblock**. Right-click > **Edit** lets you read the script first.

---

## What you see in the window

**Modes tab**
- Four buttons, one per mode, each showing how many apps it would remove on *this* PC.
- The description of the selected mode and the full list of apps up to that level, with their **status**.
- A filter (*All*, *Only those that can be removed*, *Already removed / not installed*) and a summary line with the counts.
- One button: **Remove N apps**. It only counts and removes apps that can be removed.

**Custom tab**
- The same list with a checkbox per app. Apps that can't be removed are greyed out and can't be ticked.
- **Up to Basic / Standard / Advanced / Ultra** tick everything up to that level. **Untick all** clears the selection.
- **Remove selected (N)**.

**Bottom**
- A log of what is being done, and the language selector (top right).
- **Create a restore point first (recommended)** is ticked by default.

---

## The four modes

Each mode removes its own level and **all the previous ones**.

| Mode | Tag | What it removes |
|---|---|---|
| **1. Basic** | 100% safe | Advertising only: games and sponsored apps installed by Windows or the manufacturer (Candy Crush and other King games, Gameloft and casino games, TikTok, Facebook, Instagram, X, LinkedIn, Photoshop Express, Duolingo, Pandora, Flipboard, Shazam, iHeartRadio, McAfee and Dropbox offers) and the Microsoft 365 hub shortcut. Doesn't touch any Microsoft app you use. |
| **2. Standard** | balanced | Basic + Microsoft apps almost nobody uses or that were discontinued: News, Weather, Sports/Finance/Travel/Food/Health, Maps, Tips, Feedback Hub, Solitaire, People, Mail and Calendar, Skype, Cortana, 3D Viewer / Paint 3D / Print 3D, Mixed Reality Portal, Movies & TV, Wallet / Messaging / Mobile Plans, Power Automate, Dev Home, Journal, Clipchamp, and pre-installed streaming apps (Spotify, Netflix, Disney+, Prime Video). |
| **3. Advanced** | recommended for gaming | Standard + apps that run in the background or start with Windows (Widgets, Phone Link, Teams, Copilot) and secondary apps (new Outlook, OneNote for Windows 10, To Do, Get Help, Family Safety, Sound Recorder, Quick Assist, Xbox Console Companion). Keeps Xbox, Calculator, Camera and Photos. |
| **4. Ultra** | maximum | Advanced + everything that can be removed without breaking Windows: the whole of Xbox (app, Game Bar and Xbox sign-in), Calculator, Camera, Photos, Media Player, Alarms & Clock, Sticky Notes and OneDrive. |

> **Ultra warning:** Game Pass / Microsoft Store games and games that use an Xbox account (Minecraft, Forza, Sea of Thieves...) stop working without the Xbox sign-in component. The confirmation window warns you when it is included. OneDrive: files that are only online stop opening, so download them first.

---

## App status: removable, removed, not installed

Every app of the catalog is listed with one of three states:

| Status | Meaning |
|---|---|
| **Can be removed** (green) | It is installed for some user, or provisioned for new accounts, on this PC right now. Only these can be ticked and removed. |
| **Removed (date)** (blue) | It is no longer installed and it was removed earlier **with this tool**. The date comes from the tool's own log. |
| **Not installed** (grey) | It is no longer installed, but there is no record of this tool removing it: another tool removed it, or it was never on this PC. |

The tool can't tell "removed by something else" from "never installed", because Windows doesn't keep that information, so both show as *Not installed*.

After a removal the lists refresh, and the apps you just removed move to *Removed*.

---

## Languages

The window, the app names and descriptions, the dialogs and the log are available in:

| Language | Code |
|---|---|
| English | `en` |
| Português | `pt` |
| Français | `fr` |
| Español | `es` |

On the first run the language of Windows is used (English if it isn't one of these). Pick another one in the selector at the top right; the choice is saved in `%LOCALAPPDATA%\Debloat_GUI\language.txt` and used next time.

---

## Safety

- **Known list only.** Apps are matched against the catalog in the script. Anything that isn't in the catalog is never removed.
- **Protected components.** Even if a catalog pattern matched them, these are skipped: Microsoft Store, Store Purchase App, App Installer (winget), Windows Security, VC++ / .NET / XAML runtimes, image and video codecs (HEIF, HEVC, VP9, WebP, AV1, MPEG-2, AVC, RAW), Notepad, Paint, Windows Terminal, Snipping Tool, shell and Start menu components and the Settings app.
- **Confirmation.** You see the list of what will be removed and must confirm.
- **Restore point.** Created before removing (option, on by default). If it can't be created (System Protection is off, or Windows already created one in the last 24 hours), you are asked whether to continue anyway.
- **No other changes.** The tool doesn't edit the registry, services or scheduled tasks and installs nothing. It removes Microsoft Store (Appx) packages and, for OneDrive, runs OneDrive's own uninstaller.
- **How it removes.** An app is removed for every user (`Remove-AppxPackage -AllUsers`) and its provisioned copy is removed too, so it isn't installed again on new accounts. If removal for all users fails, it tries for the current user only.
- **`ExecutionPolicy Bypass`** applies to this one PowerShell process only. Your system policy isn't changed.
- **Nothing is sent anywhere.** The tool doesn't use the network.

---

## Logs and reinstalling apps

Every removal writes a log in `%LOCALAPPDATA%\Debloat_GUI\`, named `removed_YYYYMMDD_HHMMSS.txt`. It lists the removed apps with their package names, and the ones that failed.

- The lists use these logs to show **Removed (date)**. Don't delete them if you want that information.
- Logs from version 2.0.0 (`removidas_*.txt`) are still read.
- **Reinstall an app:** search for it in the Microsoft Store and install it again. The log tells you which package it was.
- **Undo everything:** use the restore point named *Before Debloat GUI* (or *Antes do Debloat GUI*, *Avant Debloat GUI*, *Antes de Debloat GUI*, depending on the language) in *System Protection > System Restore*.

---

## FAQ

**Which mode should I use?**
*Standard* is a good balance for most people. *Advanced* is the one recommended for gaming PCs, because it removes what runs in the background (Widgets, Teams, Phone Link, Copilot) while keeping Xbox, Calculator, Camera and Photos. *Ultra* is for when you are sure you don't use any of those. *Basic* removes nothing but advertising.

**Will it make my PC faster?**
Removing apps frees disk space and cleans the Start menu. The real performance gain comes from what runs in the background (Widgets, Teams, Phone Link, OneDrive: Advanced and Ultra modes). Apps you don't open don't slow the PC down.

**Is it safe?**
It only removes a fixed list of apps, shows you the list first and can create a restore point. Still, use it at your own risk and read the Ultra warning.

**Why is an app I expected in the list shown as *Not installed*?**
It isn't installed on this PC (any more). Some apps don't exist on every Windows build.

**Can I use it on a work PC?**
Check with your IT department first. Managed PCs may block the removal or reinstall apps.

**Does it remove Microsoft Edge, the Microsoft Store or Windows Security?**
No. They are protected and not in the catalog.

**Will Windows reinstall the apps after an update?**
Apps removed for all users and from the provisioning list aren't installed again for new accounts. A big Windows feature update can bring some of them back; run the tool again.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Nothing happens when I double-click | Make sure the file still ends in `.cmd`, not `.cmd.txt`, and unblock it as described in [Quick start](#quick-start). |
| The administrator prompt was declined | The tool exits without changing anything. Open it again and accept. |
| An app fails to be removed | The log shows the Windows error. Close the app, restart the PC and try again. Some apps can't be removed on managed PCs. |
| "A restore point could not be created" | Turn on System Protection for the system drive (*Create a restore point* in the Start menu), or continue without one. Windows allows only one restore point every 24 hours by default. |
| The list shows nothing as removable | The apps of the catalog aren't on this PC, or the filter is set to *Already removed / not installed*. |
| An app is still in the Start menu after removal | Restart the PC. |
| Text with strange characters | The file must stay saved as UTF-8. Don't re-save it with another encoding. |

---

## Limitations

- **Windows 10 and 11 only.** The app list is the one found on recent builds; names of packages can change in new Windows versions.
- **The tool only knows what it removed itself.** *Removed (date)* depends on its logs.
- **It doesn't touch startup entries, services or scheduled tasks.** It only removes apps.
- **Tested on a limited number of systems.** Feedback is welcome.

---

## Contributing

Issues and pull requests are welcome: apps missing from the catalog, packages that changed name, translations, or fixes for a specific Windows build. Please say which Windows version you tested on.

**Adding an app:** add one entry to the `$Catalog` list in `Debloat_Gui.cmd`:

```powershell
@{ N = L 'Pt name' 'English name' 'Nom français' 'Nombre español'; T = 2; P = @('Package.Name*')
   D = L 'Descrição' 'Description' 'Description' 'Descripción' }
```

`T` is the level (1 to 4), `P` the package names (wildcards allowed; see them with `Get-AppxPackage -AllUsers | Select Name`) and `N` / `D` the name and the description in four languages. Never add anything that is in the `$Protected` list.

**Adding a language:** add its code and name to `$Langs` and `$LangNames` at the top, then add one more value to every `L` call (the helper that holds the four texts of a string) in the same order. Every `L` call must have the same number of values as there are languages, or the missing text will be empty in that language.

**Rules for editing the script:**
- Keep `.cmd` files with **CRLF** line endings (`.gitattributes` enforces this) and saved as **UTF-8**.
- In single-quoted PowerShell strings, double the apostrophes (`''`) and never use typographic quotes: PowerShell treats them as quotes.

---

## Repository layout

```
Debloat_Gui.cmd   # the app (batch launcher + PowerShell window)
README.md         # this file
CHANGELOG.md      # version history
LICENSE           # MIT license
.gitattributes    # keeps CRLF line endings for .cmd files
```

---

## Disclaimer

This project is not affiliated with, endorsed by or connected to Microsoft. Windows, Xbox, OneDrive, Microsoft Store and the other product names belong to their owners.

The tool is provided "as is", without warranty of any kind. Removing apps changes your system: create a restore point, read the list before confirming and use it at your own risk.

---

## License

[MIT](LICENSE)
