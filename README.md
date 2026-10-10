# ArchDesktop

Arch Linux + KDE Plasma 6 for a ready-to-use desktop environment from a live Arch environment.

This repository combines:

- a guided Arch installer that wipes a target disk and installs the base system
- KDE Plasma + SDDM setup scripts
- Layan KDE theme integration
- a custom wallpaper and Bibata cursor theme
- optional application selection for common desktop tools

> Warning: This project is intentionally destructive. It formats a selected disk and installs a new Arch system. Use it only on hardware you are prepared to wipe.

## Highlights

- Full Arch base installation flow from an ISO environment
- KDE Plasma desktop with minimal but usable default setup
- SDDM login manager configuration
- Layan look-and-feel theme package integration
- Kvantum styling, custom background, and icon/cursor setup
- Optional package selection for Git, SSH, VS Code, Docker, Discord, Steam, qBittorrent, and Wine
- Built around a modular Bash script layout for easier customization

## What this repo installs

The project is designed to produce a KDE-based Arch desktop with a polished theme stack. The included automation configures:

- base system installation and boot partitioning
- swap and recovery layout creation
- KDE Plasma and SDDM
- Kvantum styling for widget appearance
- Layan theme packages for Plasma look-and-feel
- custom wallpaper on the desktop and login screen
- default icon and cursor theme selection
- system tray, taskbars, and layout tweaks
- common desktop applications based on user selection

## Prerequisites

This installer is intended to run from a live Arch Linux environment or any environment where Arch tools are available.

You should have:

- a bootable Arch ISO or similar live environment
- root access
- the target disk identified and confirmed to be disposable
- a stable internet connection during installation
- a machine that can be wiped and repartitioned

## Important warning

This script performs destructive steps:

- it wipes the target disk
- creates new GPT partitions
- formats the boot, swap, recovery, and root partitions
- installs Arch to the selected disk

Do not run it on a drive containing important data.

## Quick start

From a live Arch environment:

```bash
sudo pacman -S git
git clone https://github.com/<your-user>/ArchInstall.git
cd ArchInstall
sudo bash install.sh
```

During the installer, you will be asked for:

- the target disk name
- locale and keyboard layout
- hostname
- user name and password
- optional package selections

## Installation flow

The main script orchestrates a multi-stage install process:

1. Detect and select the target disk
2. Prompt for locale, keyboard, and user details
3. Offer optional applications for installation
4. Execute the module-based base Arch setup
5. Configure the new system in chroot
6. Install KDE Plasma and SDDM
7. Apply Layan KDE theme, wallpaper, icons and cursor styling
8. Install optional desktop apps and services
9. Reboot into the new system

The underlying modules are intentionally separated so you can customize them without rewriting the main install script.

## Included theme stack

### KDE Plasma / Layan

The repository includes a bundled Layan theme set based on the upstream Layan KDE Plasma customization project. The bundled installer applies Plasma look-and-feel, Aurorae themes, Kvantum themes, widgets, color schemes, and SDDM assets.

### Cursor theme

The repo also includes the Bibata Modern Ice cursor theme archive, which is extracted into the system icon directories and configured as the default cursor theme.

### Wallpaper

A custom wallpaper is copied into the system and configured for both the desktop background and login screen.

## Optional software choices

The installer lets the user select optional apps from a menu. The current automation supports:

- Git
- SSH
- VS Code
- Docker
- Discord
- Steam
- qBittorrent
- Wine

These flags are processed inside the installer and passed to the app provisioning scripts.

## Project scripts and purpose

### Main installer

- `install.sh`: entry point for the full disk wipe and Arch installation workflow

### Module scripts

- `base_install.sh`: prepares partitions, formats filesystems, installs the base system
- `chroot_config.sh`: configures localization, user creation, and base system settings
- `kde_setup.sh`: installs KDE runtime components and base desktop packages
- `kde_theme.sh`: applies Layan, wallpaper, icon, and cursor customizations
- `apps_setup.sh`: installs selected applications and relevant services
- `audio_setup.sh`: configures audio stack
- `power_setup.sh`: powersaving / performance defaults
- `video_setup.sh`: graphics driver and display preparation
- `get_partitions.sh`: partition lookup and helper logic

## Customization notes

If you want to personalize the installer:

- update the package prompts in `install.sh`
- change the default theme configuration in `.modules/kde_theme.sh`
- replace the wallpaper image at the project root
- swap the cursor archive with another Bibata or icon package
- modify the KDE app install list in `.modules/apps_setup.sh`

## License and attribution

This repository includes upstream project assets and scripts. Please review the license and attribution files in the included theme directories before redistributing or publishing forks.

The bundled Layan KDE theme is distributed under its own licensing terms, and the repository includes the upstream project files for that theme. See the theme directory for exact license details.

## Recommended usage

This repo is best used when you want a fully customized Arch KDE workstation instead of a minimal default install. It is a strong fit for:

- developers who want a pre-themed KDE environment
- users building a repeatable personal workstation setup
- lab or testing machines that need a consistent desktop profile
- people comfortable with the Arch installation workflow and disk partitioning

## Troubleshooting

If the install fails:

- verify you selected the correct disk name
- check that the live environment has internet access
- confirm your system supports the packages being installed
- inspect the module scripts for the step where the failure occurred
- rerun from a clean Arch live ISO if the installation process was interrupted

## Contributing

Pull requests and customizations are welcome if they improve:

- Arch install reliability
- KDE configuration quality
- theme correctness
- package selection logic
- documentation clarity

## Final note

This project is a personal Arch installer and desktop configuration bundle. It is designed to be practical, reproducible, and tailored to a KDE-first workflow. If you are using it as a base for your own installation, it is best to review all scripts before running them on a real machine.
