#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Configure XFCE

set -e

JETBRAINS_MONO_VERSION="2.304"
SWEET_DARK_VERSION="5.0"

backup_actual_xfce_configuration() {
    XFCE_BACKUP=$(mktemp -t xfce-XXXXXXX)

    for CHANNEL in $(xfconf-query -l | sed -e "1d" -e "s/ //g")
    do
        for PROPERTY in $(xfconf-query -c $CHANNEL -lv | tr -s " " | tr " " ";")
        do
            KEY="$(echo "$PROPERTY" | cut -f1 -d ";")"
            VALUE="$(echo "$PROPERTY" | cut -f2 -d ";")"

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

apply_xfce_settings_fonts() {
    xfconf-query -c xfce4-panel -p /plugins/plugin-5/digital-time-font -s "JetBrains"
    xfconf-query -c xfce4-terminal -p /font-name -s "JetBrains"
    xfconf-query -c xfwm4 -p /general/title_font -s "JetBrains"
    xfconf-query -c xsettings -p /Gtk/FontName -s "JetBrains"
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "JetBrains"
}

apply_xfce_settings() {
    apply_xfce_settings_fonts
}



backup_actual_xfce_configuration
