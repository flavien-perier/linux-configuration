#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Configure XFCE

set -e
set -x

JETBRAINS_MONO_VERSION="2.304"
SWEET_DARK_VERSION="5.0"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

backup_actual_configuration() {
    XFCE_BACKUP=$(mktemp -t xfce-XXXXXXX)

    for CHANNEL in $(xfconf-query -l | sed -e "1d" -e "s/ //g")
    do
        for PROPERTY in $(xfconf-query -n -c $CHANNEL -lv | tr -s " " | tr " " ";")
        do
            KEY="$(echo "$PROPERTY" | cut -f1 -d ";")"
            VALUE="$(echo "$PROPERTY" | cut -f2- -d ";" | tr ";" " ")"

            echo "xfconf-query -n -c $CHANNEL -p $KEY -t string -s \"$VALUE\"" >> $XFCE_BACKUP
        done
    done

    printf "Actual XFCE configuration is backup in : \033[0;36m$XFCE_BACKUP\033[0m\n"
}

download_resources() {
    TEMP_DIR=`mktemp -d`

    rm -Rf "$HOME/.fonts"
    mkdir -p "$HOME/.fonts"
    wget https://github.com/JetBrains/JetBrainsMono/releases/download/v$JETBRAINS_MONO_VERSION/JetBrainsMono-$JETBRAINS_MONO_VERSION.zip \
        -O "$TEMP_DIR/JetBrainsMono.zip"
    unzip -j "$TEMP_DIR/JetBrainsMono.zip" -d "$HOME/.fonts" fonts/ttf/*.ttf

    rm -Rf "$HOME/.icons"
    mkdir -p "$HOME/.icons"
    wget https://github.com/EliverLara/Sweet-folders/archive/refs/heads/master.zip \
        -O "$TEMP_DIR/Sweet-icon.zip"
    unzip "$TEMP_DIR/Sweet-icon.zip" -d "$HOME/.icons" Sweet-folders-master/Sweet-Rainbow/*
    mv $HOME/.icons/Sweet-folders-master/Sweet-Rainbow $HOME/.icons/Sweet-Rainbow
    rmdir $HOME/.icons/Sweet-folders-master

    rm -Rf "$HOME/.themes"
    mkdir -p "$HOME/.themes"
    wget https://github.com/EliverLara/Sweet/releases/download/v$SWEET_DARK_VERSION/Sweet-Dark-v40.tar.xz \
        -O "$TEMP_DIR/Sweet-Dark.tar.xz"
    tar -xJf "$TEMP_DIR/Sweet-Dark.tar.xz" -C "$HOME/.themes"
}

apply_settings_fonts() {
    xfconf-query -n -c xfce4-panel -p /plugins/plugin-5/digital-time-font -t string -s "JetBrains Mono Bold 13"
    xfconf-query -n -c xfce4-terminal -p /font-name -t string -s "JetBrains Mono NL 15"
    xfconf-query -n -c xfwm4 -p /general/title_font -t string -s "JetBrains Mono NL Bold 14"
    xfconf-query -n -c xsettings -p /Gtk/FontName -t string -s "JetBrains Mono NL 13"
    xfconf-query -n -c xsettings -p /Gtk/MonospaceFontName -t string -s "JetBrains Mono NL Light 10"
}

apply_settings_theme() {
    xfconf-query -n -c xfwm4 -p /general/theme -t string -s "Sweet-Dark-v40"
    xfconf-query -n -c xsettings -p /Net/IconThemeName -t string -s "Sweet-Rainbow"
    xfconf-query -n -c xsettings -p /Net/ThemeName -t string -s "Sweet-Dark-v40"
}

apply_settings_terminal() {
    xfconf-query -n -c xfce4-terminal -p /tab-activity-color -t string -s "#ff7f7f"
    xfconf-query -n -c xfce4-terminal -p /color-foreground -t string -s "#ffffff"
    xfconf-query -n -c xfce4-terminal -p /color-background -t string -s "#000000"
    xfconf-query -n -c xfce4-terminal -p /color-bold -t string -s "#ffffff"
    xfconf-query -n -c xfce4-terminal -p /color-bold-use-default -t bool -s false
    xfconf-query -n -c xfce4-terminal -p /color-cursor -t string -s "#ffffff"
    xfconf-query -n -c xfce4-terminal -p /color-cursor-foreground -t string -s "#000000"
    xfconf-query -n -c xfce4-terminal -p /color-cursor-use-default -t bool -s false
    xfconf-query -n -c xfce4-terminal -p /color-selection -t string -s "#000000"
    xfconf-query -n -c xfce4-terminal -p /color-selection-background -t string -s "#ffffff"
    xfconf-query -n -c xfce4-terminal -p /color-selection-use-default -t bool -s false
    xfconf-query -n -c xfce4-terminal -p /color-palette -t string -s "#404040;#d04040;#40d040;#d0d040;#4040d0;#d040d0;#40d0d0;#d0d0d0;#7f7f7f;#ff7f7f;#7fff7f;#ffff7f;#7f7fff;#ff7fff;#7fffff;#ffffff"

    xfconf-query -n -c xfce4-terminal -p /background-mode -t string -s "TERMINAL_BACKGROUND_TRANSPARENT"
    xfconf-query -n -c xfce4-terminal -p /background-darkness -t double -s 0.9

    xfconf-query -n -c xfce4-terminal -p /title-mode -t string -s "TERMINAL_TITLE_HIDE"
    xfconf-query -n -c xfce4-terminal -p /scrolling-unlimited -t bool -s true

    if command_exists "tmux"
    then
        xfconf-query -n -c xfce4-terminal -p /run-custom-command -t bool -s true
        xfconf-query -n -c xfce4-terminal -p /custom-command -t string -s "tmux"
        xfconf-query -n -c xfce4-terminal -p /scrolling-bar -t string -s "TERMINAL_SCROLLBAR_NONE"
    fi
}

main() {
    download_resources

    apply_settings_fonts
    apply_settings_theme
    apply_settings_terminal
}

main
