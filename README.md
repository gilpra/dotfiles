# Dotfiles

Personal dotfiles for Linux.

Each profile directory contains the configuration files for a specific environment. Installation scripts and package lists in `.setup/`.

## Preview

| Sway | Hyprland | XFCE |
| :---: | :---: | :---: |
| [<img src="https://raw.githubusercontent.com/gilpra/assets-repo/main/screenshots/sway_1.png" width="300">](https://raw.githubusercontent.com/gilpra/assets-repo/main/screenshots/sway_1.png) | [<img src="https://raw.githubusercontent.com/gilpra/assets-repo/main/screenshots/hyprland_1.png" width="300">](https://raw.githubusercontent.com/gilpra/assets-repo/main/screenshots/hyprland_1.png) | [<img src="https://raw.githubusercontent.com/gilpra/assets-repo/main/screenshots/xfce_1.png" width="300">](https://raw.githubusercontent.com/gilpra/assets-repo/main/screenshots/xfce_1.png) |

## Setup

Clone the repository:

```bash
git clone https://github.com/gilpra/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Run the setup for your profile:

```bash
./setup.sh sway
./setup.sh hyprland
./setup.sh xfce
```

Wallpapers and other assets are managed separately in my [assets-repo](https://github.com/gilpra/assets-repo).
