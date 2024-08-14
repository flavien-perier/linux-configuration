#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Configure XFCE

set -e

JETBRAINS_MONO_VERSION="2.304"
SWEET_DARK_VERSION="5.0"

backup_actual_configuration() {
    XFCE_BACKUP=$(mktemp -t xfce-XXXXXXX)

    for CHANNEL in $(xfconf-query -l | sed -e "1d" -e "s/ //g")
    do
        for PROPERTY in $(xfconf-query -c $CHANNEL -lv | tr -s " " | tr " " ";")
        do
            KEY="$(echo "$PROPERTY" | cut -f1 -d ";")"
            VALUE="$(echo "$PROPERTY" | cut -f2- -d ";" | tr ";" " ")"

            echo "xfconf-query -c $CHANNEL -p $KEY -s \"$VALUE\"" >> $XFCE_BACKUP
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
        -O "$TEMP_DIR/Sweet-Dark.tar.xz" "$HOME/.themes"
    tar -xJf "$TEMP_DIR/Sweet-Dark.tar.xz" -C "$HOME/.themes"
}

apply_settings_fonts() {
    xfconf-query -c xfce4-panel -p /plugins/plugin-5/digital-time-font -s "JetBrains Mono Bold 13"
    xfconf-query -c xfce4-terminal -p /font-name -s "JetBrains Mono NL 15"
    xfconf-query -c xfwm4 -p /general/title_font -s "JetBrains Mono NL Bold 14"
    xfconf-query -c xsettings -p /Gtk/FontName -s "JetBrains Mono NL 13"
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "JetBrains Mono NL Light 10"
}

apply_settings_theme() {
    xfconf-query -c xfwm4 -p /general/theme -s "Sweet-Dark-v40"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Sweet-Rainbow"
    xfconf-query -c xsettings -p /Net/ThemeName -s "Sweet-Dark-v40"
}

apply_settings_terminal() {
    xfconf-query -c xfce4-terminal -p /tab-activity-color -s "#ff7f7f"
    xfconf-query -c xfce4-terminal -p /color-foreground -s "#ffffff"
    xfconf-query -c xfce4-terminal -p /color-background -s "#000000"
    xfconf-query -c xfce4-terminal -p /color-bold -s "#ffffff"
    xfconf-query -c xfce4-terminal -p /color-bold-use-default -s false
    xfconf-query -c xfce4-terminal -p /color-cursor -s "#ffffff"
    xfconf-query -c xfce4-terminal -p /color-cursor-foreground -s "#000000"
    xfconf-query -c xfce4-terminal -p /color-cursor-use-default -s false
    xfconf-query -c xfce4-terminal -p /color-selection -s "#000000"
    xfconf-query -c xfce4-terminal -p /color-selection-background -s "#ffffff"
    xfconf-query -c xfce4-terminal -p /color-selection-use-default -s false
    xfconf-query -c xfce4-terminal -p /color-palette -s "#404040;#d04040;#40d040;#d0d040;#4040d0;#d040d0;#40d0d0;#d0d0d0;#7f7f7f;#ff7f7f;#7fff7f;#ffff7f;#7f7fff;#ff7fff;#7fffff;#ffffff"

    xfconf-query -c xfce4-terminal -p /background-mode -s "TERMINAL_BACKGROUND_TRANSPARENT"
    xfconf-query -c xfce4-terminal -p /background-darkness -s 0.9
}

main() {
    download_resources

    apply_settings_fonts
    apply_settings_theme
    apply_settings_terminal
}

main
