#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Configure XFCE

set -e

JETBRAINS_MONO_VERSION="2.304"
SWEET_DARK_VERSION="5.0"

GITHUB_PROJECT_BASE_URL="https://raw.githubusercontent.com/flavien-perier/linux-configuration/master"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

download_resources() {
    local HOME_DIR=$1

    local TEMP_DIR=`mktemp -d /tmp/xfce.XXXXXXXXXX`
    local FONTS_DIR="$HOME_DIR/.fonts"
    local ICONS_DIR="$HOME_DIR/.icons"
    local THEMES_DIR="$HOME_DIR/.themes"

    # Fonts
    chmod -R 700 $FONTS_DIR || echo "No fonts dir"
    rm -Rf $FONTS_DIR
    mkdir -p $FONTS_DIR

    wget https://github.com/JetBrains/JetBrainsMono/archive/refs/heads/master.zip \
        -O "$TEMP_DIR/JetBrainsMono.zip"
    unzip -qq -j "$TEMP_DIR/JetBrainsMono.zip" -d $FONTS_DIR JetBrainsMono-master/fonts/ttf/*.ttf

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

    wget $GITHUB_PROJECT_BASE_URL/xfce/icons/flavien.png -O $ICONS_DIR/flavien.png
    wget $GITHUB_PROJECT_BASE_URL/xfce/icons/manjaro.png -O $ICONS_DIR/manjaro.png

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

    curl $GITHUB_PROJECT_BASE_URL/xfce/xconf/xfce4-keyboard-shortcuts.xml > $CONF_DIR/xfce4-keyboard-shortcuts.xml
    curl $GITHUB_PROJECT_BASE_URL/xfce/xconf/xfce4-panel.xml > $CONF_DIR/xfce4-panel.xml
    curl $GITHUB_PROJECT_BASE_URL/xfce/xconf/xfce4-terminal.xml > $CONF_DIR/xfce4-terminal.xml
    curl $GITHUB_PROJECT_BASE_URL/xfce/xconf/xfwm4.xml > $CONF_DIR/xfwm4.xml
    curl $GITHUB_PROJECT_BASE_URL/xfce/xconf/xsettings.xml > $CONF_DIR/xsettings.xml

    if ! command_exists "tmux"
    then
        sed -i \
            -e 's|<property name="run-custom-command" type="bool" value="true"/>|<property name="run-custom-command" type="bool" value="false"/>|g' \
            -e 's|<property name="scrolling-bar" type="string" value="TERMINAL_SCROLLBAR_NONE"/>|<property name="scrolling-bar" type="string" value="TERMINAL_SCROLLBAR_RIGHT"/>|g'\
            $GITHUB_PROJECT_BASE_URL/xfce/xconf/xfce4-terminal.xml
    fi
}

apply_tmux_settings() {
    local HOME_DIR=$1

    if command_exists "tmux"
    then
        curl $GITHUB_PROJECT_BASE_URL/xfce/tmux.conf > $HOME_DIR/.tmux.conf
    fi
}

main() {
    command_exists "wget" || (echo "wget not found" && exit 1)
    command_exists "curl" || (echo "curl not found" && exit 1)
    command_exists "unzip" || (echo "unzip not found" && exit 1)
    command_exists "xz" || (echo "xz not found" && exit 1)

    local HOME_DIR=${1:-"$HOME"}
    local CONF_DIR=${2:-"$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"}

    mkdir -p $HOME_DIR
    mkdir -p $CONF_DIR

    download_resources $HOME_DIR
    apply_xfce_settings $CONF_DIR
    apply_tmux_settings $HOME_DIR
}

main $*
