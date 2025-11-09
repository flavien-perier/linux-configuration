![license](https://badgen.net/github/license/flavien-perier/linux-configuration)

# Linux Configuration

## 1) `shell.sh` — User shell configuration

![Shell preview](./doc/shell.png)

This script installs base tools and configures the three shells `bash`, `zsh`, and `fish` to provide a consistent prompt.

- Main features
    - provide a consistent prompt (time, active shell, user@host, current directory, Git branch with clean/dirty status, duration of last command if > 250 ms, and non‑zero exit code).
    - Detects the package manager (`apt-get`, `yum`, `dnf`, `apk`, `pacman`) and quietly installs tools :
        - [zsh](https://sourceforge.net/p/zsh/code/ci/master/tree/)
        - [fish](https://fishshell.com/)
        - [git](https://git-scm.com/)
        - [htop](https://htop.dev/)
        - [neovim](https://neovim.io/)
        - [tree](https://linux.die.net/man/1/tree)
        - [eza](https://github.com/eza-community/eza)
        - [ripgrp](https://github.com/BurntSushi/ripgrep)
        - [fd](https://github.com/sharkdp/fd)
        - [bat](https://github.com/sharkdp/bat)
        - [dust](https://github.com/bootandy/dust)
    - Installs user utilities in `~/bin` when not root (auto-detects architecture x86_64/arm64/arm) :
        - [kubectl](https://kubernetes.io/fr/docs/reference/kubectl/)
        - [kubectx](https://github.com/ahmetb/kubectx)
        - [kubens](https://github.com/ahmetb/kubectx)
        - [kompose](https://kompose.io/)
    - Installs the Zsh plugin manager [`zsh-snap`](https://github.com/marlonrichert/zsh-snap) and enables :
      - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
      - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
    - Generates configs for `~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`, and `~/.config/nvim/init.vim`.
    - Creates an `~/.alias` file with useful aliases (`ls/ll` via `eza` if present, `vi` -> `nvim` if present, colored `grep`, etc.).
    - Optionally updates users’ default shell (prefers `fish`, otherwise `zsh`) when possible.
    - Supports running as root (configures all users in `/home`, `root`, and `/etc/skel`) or unprivileged (configures only the current user).

- Requirements
    - Internet access.
    - To run without root: `curl`, `git`, and `awk` must be available.

- Usage
    - Recommended install (all users, requires sudo/root):
      ```sh
      curl -s https://sh.flavien.io/shell.sh | sudo sh -
      ```
    - Local run (from the cloned repo):
      ```sh
      sudo ./shell.sh
      # or for current user only (no sudo; requires curl+git+awk)
      ./shell.sh
      ```

## 2) `xfce.sh` — XFCE themes, fonts, and settings (plus Sway/Tmux)

![XFCE preview](./doc/xfce.png)

This script downloads and applies a full customization for an XFCE environment, with optional settings for Sway and tmux when available.

- Main features
    - Fonts: [JetBrainsMono](https://www.jetbrains.com/lp/mono/) with [Nerd Font](https://www.nerdfonts.com/).
    - Icons: [Sweet-Rainbow](https://github.com/EliverLara/Sweet-folders) and [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).
    - Cursor: [Breeze cursors](https://github.com/KDE/breeze).
    - Theme: [Sweet-Dark](https://github.com/EliverLara/Sweet).
    - XFCE: applies configuration files from this repo (`xfce/xconf/*.xml`).
    - tmux: installs `~/.tmux.conf` if `tmux` is available.
    - Sway: installs `~/.config/sway/config` and `config.d/{keyboard,theme}` if `sway` is available.

- Requirements
    - Internet access.
    - Tools: `wget`, `curl`, `unzip`, `xz`.

- Usage
    - For the current user’s home directory:
      ```sh
      curl -s https://sh.flavien.io/xfce.sh | sh -
      ```
    - To prepare a `/etc/skel` skeleton (useful for future users):
      ```sh
      sudo ./xfce.sh /etc/skel
      ```

## 3) `arch.sh` — Automated Arch Linux base install + XFCE

![Arch preview](./doc/arch.png)

Installation script intended to be run from an Arch Linux live environment. It partitions the disk, installs a base system, and sets up a ready-to-use XFCE desktop.

- What the script does
    - GPT partitioning of the target disk with `parted`:
        - `p1` EFI (FAT32, ~500 MiB), `p2` swap (~4 GiB), `p3` Btrfs (rest of the disk).
    - Creates Btrfs subvolumes `@` and `@home`.
    - Base install via `pacstrap`: `base`, `linux`, `linux-firmware`, `grub`, `efibootmgr`, `systemd`, `networkmanager`, `sudo`, `pacman`, `flatpak`.
    - Installs the XFCE environment (panel, apps, plugins, terminal, etc.) + `sway` + `lightdm` and enables `lightdm`.
    - Applies XFCE/Tmux/Sway configuration to the skeleton (`/etc/skel`) via `xfce.sh`, then adjusts the default icon.
    - French locale by default: `fr_FR.UTF-8`, keyboard `fr`, timezone `Europe/Paris` (links and `locale-gen`).
    - Creates a user, adds it to the `sudo` group, sets the password.
    - Installs shell configuration for everyone via `shell.sh` inside the `chroot`.
    - Adds the `flathub` remote (Flatpak) for the created user.
    - Installs and generates GRUB configuration.

- Warnings / Requirements
    - DANGEROUS: the disk passed as argument will be repartitioned and fully erased (`parted mklabel gpt`). Back up your data before running.
    - To be used on Arch Linux (installation ISO) only.
    - Internet connection required.

- Usage
    - Run from an Arch live session with root privileges and an Internet connection:
      ```sh
      # Interactive mode (whiptail dialogs):
      curl -s https://sh.flavien.io/arch.sh | sh -
      
      # Non-interactive mode (4 arguments):
      # ./arch.sh <HOSTNAME> <DISK> <USERNAME> <PASSWORD>
      ./arch.sh my-host /dev/sda alice "MyStrongPassword"
      ```

