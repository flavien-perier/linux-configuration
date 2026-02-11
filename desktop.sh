#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Configure XFCE

set -e

JET_BRAINS_MONO_NERD_VERSION="3.4.0"
SWEET_DARK_VERSION="6.0"

GITHUB_PROJECT_BASE_URL="https://raw.githubusercontent.com/flavien-perier/linux-configuration/master/desktop"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

download_themes() {
    local HOME_DIR=$1

    local TEMP_DIR=$(mktemp -d /tmp/xfce.XXXXXXXXXX)
    local FONTS_DIR="$HOME_DIR/.fonts"
    local ICONS_DIR="$HOME_DIR/.icons"
    local THEMES_DIR="$HOME_DIR/.themes"

    # Fonts
    chmod -R 700 $FONTS_DIR || echo "No fonts dir"
    rm -Rf $FONTS_DIR
    mkdir -p $FONTS_DIR

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v$JET_BRAINS_MONO_NERD_VERSION/JetBrainsMono.zip \
        -O "$TEMP_DIR/JetBrainsMono.zip"
    unzip -qq -j "$TEMP_DIR/JetBrainsMono.zip" -d $FONTS_DIR "JetBrainsMonoNerdFont-*.ttf"

    # Icons
    chmod -R 700 $ICONS_DIR || echo "No icons dir"
    rm -Rf $ICONS_DIR
    mkdir -p $ICONS_DIR

    wget https://github.com/EliverLara/Sweet-folders/archive/refs/heads/master.zip \
        -O "$TEMP_DIR/Sweet-icon.zip"
    unzip -qq "$TEMP_DIR/Sweet-icon.zip" -d $ICONS_DIR Sweet-folders-master/Sweet-Rainbow/*
    mv $ICONS_DIR/Sweet-folders-master/Sweet-Rainbow $ICONS_DIR/Sweet-Rainbow
    rmdir $ICONS_DIR/Sweet-folders-master

    wget https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/heads/master.zip \
        -O "$TEMP_DIR/papirus.zip"
    unzip -qq "$TEMP_DIR/papirus.zip" -d $ICONS_DIR papirus-icon-theme-master/Papirus/*
    unzip -qq "$TEMP_DIR/papirus.zip" -d $ICONS_DIR papirus-icon-theme-master/Papirus-Dark/*
    mv $ICONS_DIR/papirus-icon-theme-master/Papirus $ICONS_DIR/Papirus
    mv $ICONS_DIR/papirus-icon-theme-master/Papirus-Dark/ $ICONS_DIR/Papirus-Dark
    rm -Rf $ICONS_DIR/papirus-icon-theme-master

    wget https://github.com/KDE/breeze/archive/refs/heads/master.zip \
        -O "$TEMP_DIR/breeze.zip"
    unzip -qq "$TEMP_DIR/breeze.zip" -d $ICONS_DIR breeze-master/cursors/Breeze/Breeze/*
    mv $ICONS_DIR/breeze-master/cursors/Breeze/Breeze $ICONS_DIR/Breeze
    rm -Rf $ICONS_DIR/breeze-master

    sed -i "s/Inherits=.*/Inherits=Papirus-Dark/g" $ICONS_DIR/Sweet-Rainbow/index.theme

    gtk-update-icon-cache $ICONS_DIR/Papirus/ || echo "Papirus theme optimisation failed"
    gtk-update-icon-cache $ICONS_DIR/Papirus-Dark/ || echo "Papirus-Dark theme optimisation failed"
    gtk-update-icon-cache $ICONS_DIR/Sweet-Rainbow/ || echo "Sweet-Rainbow theme optimisation failed"

    wget $GITHUB_PROJECT_BASE_URL/icons/flavien.png -O $ICONS_DIR/flavien.png
    wget $GITHUB_PROJECT_BASE_URL/icons/manjaro.png -O $ICONS_DIR/manjaro.png
    wget $GITHUB_PROJECT_BASE_URL/icons/arch.png -O $ICONS_DIR/arch.png

    # Themes
    chmod -R 700 $THEMES_DIR || echo "No themes dir"
    rm -Rf $THEMES_DIR
    mkdir -p $THEMES_DIR

    wget https://github.com/EliverLara/Sweet/releases/download/v$SWEET_DARK_VERSION/Sweet-Dark-v40.tar.xz \
        -O "$TEMP_DIR/Sweet-Dark.tar.xz"
    tar -xJf "$TEMP_DIR/Sweet-Dark.tar.xz" -C $THEMES_DIR

    # Chown after
    find $FONTS_DIR -type f -exec chmod 400 {} \;
    find $FONTS_DIR -type d -exec chmod 500 {} \;
    find $ICONS_DIR -type f -exec chmod 400 {} \;
    find $ICONS_DIR -type d -exec chmod 500 {} \;
    find $THEMES_DIR -type f -exec chmod 400 {} \;
    find $THEMES_DIR -type d -exec chmod 500 {} \;

    # Clean after
    rm -Rf $TEMP_DIR
}

apply_xfce_settings() {
    local CONF_DIR=$1

    mkdir -p $CONF_DIR

    curl -Lqs $GITHUB_PROJECT_BASE_URL/xconf/xfce4-keyboard-shortcuts.xml -o $CONF_DIR/xfce4-keyboard-shortcuts.xml
    curl -Lqs $GITHUB_PROJECT_BASE_URL/xconf/xfce4-panel.xml -o $CONF_DIR/xfce4-panel.xml
    curl -Lqs $GITHUB_PROJECT_BASE_URL/xconf/xfce4-terminal.xml -o $CONF_DIR/xfce4-terminal.xml
    curl -Lqs $GITHUB_PROJECT_BASE_URL/xconf/xfwm4.xml -o $CONF_DIR/xfwm4.xml
    curl -Lqs $GITHUB_PROJECT_BASE_URL/xconf/xsettings.xml -o $CONF_DIR/xsettings.xml

    if ! command_exists "tmux"; then
        sed -i \
            -e 's|<property name="run-custom-command" type="bool" value="true"/>|<property name="run-custom-command" type="bool" value="false"/>|g' \
            -e 's|<property name="scrolling-bar" type="string" value="TERMINAL_SCROLLBAR_NONE"/>|<property name="scrolling-bar" type="string" value="TERMINAL_SCROLLBAR_RIGHT"/>|g'p \
            $CONF_DIR/xfce4-terminal.xml
    fi
}

apply_tmux_settings() {
    local HOME_DIR=$1

    curl -Lqs $GITHUB_PROJECT_BASE_URL/tmux.conf -o $HOME_DIR/.tmux.conf
}

apply_sway_settings() {
    local CONF_DIR=$1

    if command_exists "sway"; then
        mkdir -p $CONF_DIR/config.d
        curl -Lqs $GITHUB_PROJECT_BASE_URL/sway/config -o $CONF_DIR/config
        curl -Lqs $GITHUB_PROJECT_BASE_URL/sway/config.d/keyboard -o $CONF_DIR/config.d/keyboard
        curl -Lqs $GITHUB_PROJECT_BASE_URL/sway/config.d/theme -o $CONF_DIR/config.d/theme
    fi
}

apply_rio_settings() {
    local CONF_DIR=$1

    if command_exists "rio"; then
        mkdir -p $CONF_DIR
        curl -Lqs $GITHUB_PROJECT_BASE_URL/rio.conf -o $CONF_DIR/config.toml
    fi
}

configure_home_dir() {
    local HOME_DIR="$1"

    mkdir -p $HOME_DIR/bin

    mv $HOME_DIR/Bureau $HOME_DIR/Desktop 2>/dev/null || true
    mv $HOME_DIR/Documents $HOME_DIR/Documents 2>/dev/null || true
    mv $HOME_DIR/Téléchargements $HOME_DIR/Downloads 2>/dev/null || true
    mv $HOME_DIR/Musique $HOME_DIR/Music 2>/dev/null || true
    mv $HOME_DIR/Images $HOME_DIR/Pictures 2>/dev/null || true
    mv $HOME_DIR/Vidéos $HOME_DIR/Videos 2>/dev/null || true
    mv $HOME_DIR/Public $HOME_DIR/Public 2>/dev/null || true
    mv $HOME_DIR/Modèles $HOME_DIR/Templates 2>/dev/null || true

    mkdir -p $HOME_DIR/Desktop
    mkdir -p $HOME_DIR/Documents
    mkdir -p $HOME_DIR/Downloads
    mkdir -p $HOME_DIR/Music
    mkdir -p $HOME_DIR/Pictures
    mkdir -p $HOME_DIR/Videos
    mkdir -p $HOME_DIR/Public
    mkdir -p $HOME_DIR/Templates

    mkdir -p $HOME_DIR/.config

    echo "en_EN" > $HOME_DIR/.config/user-dirs.locale

    echo 'XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_TEMPLATES_DIR="$HOME/Templates"' > $HOME_DIR/.config/user-dirs.dirs
}

download_bin_files() {
    local HOME_DIR="$1"

    chmod u+w $HOME_DIR/bin

    curl -Lqs $GITHUB_PROJECT_BASE_URL/bin/sh-copy -o $HOME_DIR/bin/sh-copy
    chmod 500 $HOME_DIR/bin/sh-copy

    chmod u-w $HOME_DIR/bin
}

main() {
    command_exists "wget" || (echo "wget not found" && exit 1)
    command_exists "curl" || (echo "curl not found" && exit 1)
    command_exists "unzip" || (echo "unzip not found" && exit 1)
    command_exists "xz" || (echo "xz not found" && exit 1)

    local HOME_DIR=${1:-"$HOME"}
    local XFCE_CONF_DIR="$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
    local SWAY_CONF_DIR="$HOME_DIR/.config/sway"
    local RIO_CONF_DIR="$HOME_DIR/.config/rio"

    download_themes $HOME_DIR
    apply_xfce_settings $XFCE_CONF_DIR
    apply_tmux_settings $HOME_DIR
    apply_sway_settings $SWAY_CONF_DIR
    apply_rio_settings $RIO_CONF_DIR
    configure_home_dir $HOME_DIR
    download_bin_files $HOME_DIR
}

main $*
