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
        for PROPERTY in $(xfconf-query -c $CHANNEL -lv | tr -s " " | tr " " ";")
        do
            KEY="$(echo "$PROPERTY" | cut -f1 -d ";")"
            VALUE="$(echo "$PROPERTY" | cut -f2- -d ";" | tr ";" " ")"

            echo "xfconf-query -n -c $CHANNEL -p $KEY -t string -s \"$VALUE\"" >> $XFCE_BACKUP
        done
    done

    printf "Actual XFCE configuration is backup in : \033[0;36m$XFCE_BACKUP\033[0m\n"
}

print_xfce_pannel_configuration() {
    echo '<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="0"/>
    <property name="panel-0" type="empty">
      <property name="position" type="string" value="p=8;x=720;y=884"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="8"/>
        <value type="int" value="3"/>
        <value type="int" value="7"/>
        <value type="int" value="6"/>
        <value type="int" value="20"/>
        <value type="int" value="9"/>
        <value type="int" value="5"/>
        <value type="int" value="15"/>
      </property>
      <property name="role" type="string" value="xfce4-panel-12965750720"/>
      <property name="length-adjust" type="bool" value="true"/>
      <property name="background-style" type="uint" value="0"/>
      <property name="size" type="uint" value="45"/>
      <property name="mode" type="uint" value="0"/>
      <property name="autohide-behavior" type="uint" value="0"/>
      <property name="icon-size" type="uint" value="27"/>
      <property name="nrows" type="uint" value="1"/>
      <property name="enter-opacity" type="uint" value="100"/>
      <property name="leave-opacity" type="uint" value="100"/>
      <property name="span-monitors" type="bool" value="true"/>
      <property name="output-name" type="string" value="eDP-1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0"/>
        <value type="double" value="0"/>
        <value type="double" value="0"/>
        <value type="double" value="1"/>
      </property>
      <property name="enable-struts" type="bool" value="true"/>
    </property>
    <property name="dark-mode" type="bool" value="false"/>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-3" type="string" value="tasklist">
      <property name="grouping" type="bool" value="false"/>
      <property name="sort-order" type="uint" value="4"/>
      <property name="show-handle" type="bool" value="false"/>
      <property name="show-labels" type="bool" value="false"/>
      <property name="middle-click" type="uint" value="1"/>
      <property name="flat-buttons" type="bool" value="true"/>
      <property name="include-all-monitors" type="bool" value="true"/>
      <property name="show-only-minimized" type="bool" value="false"/>
      <property name="show-tooltips" type="bool" value="false"/>
      <property name="show-wireframes" type="bool" value="false"/>
      <property name="window-scrolling" type="bool" value="false"/>
    </property>
    <property name="plugin-7" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-9" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
    </property>
    <property name="plugin-8" type="string" value="whiskermenu">
      <property name="button-icon" type="string" value="/home/flavien/.icons/logo.png"/>
      <property name="button-single-row" type="bool" value="true"/>
      <property name="launcher-show-description" type="bool" value="false"/>
      <property name="launcher-show-tooltip" type="bool" value="false"/>
      <property name="launcher-icon-size" type="int" value="3"/>
      <property name="category-icon-size" type="int" value="2"/>
      <property name="sort-categories" type="bool" value="false"/>
      <property name="recent-items-max" type="int" value="0"/>
      <property name="favorites-in-recent" type="bool" value="true"/>
      <property name="menu-width" type="int" value="696"/>
      <property name="menu-height" type="int" value="725"/>
      <property name="menu-opacity" type="int" value="95"/>
      <property name="show-command-lockscreen" type="bool" value="false"/>
      <property name="command-switchuser" type="string" value="dm-tool switch-to-greeter"/>
      <property name="show-command-restart" type="bool" value="true"/>
      <property name="show-command-shutdown" type="bool" value="true"/>
      <property name="show-command-logout" type="bool" value="false"/>
      <property name="favorites" type="array"></property>
      <property name="recent" type="array">
      </property>
    </property>
    <property name="plugin-5" type="string" value="clock">
      <property name="mode" type="uint" value="2"/>
      <property name="tooltip-format" type="string" value="%x"/>
      <property name="digital-format" type="string" value="%Y-%m-%d &lt;b&gt;%H:%M&lt;/b&gt; "/>
      <property name="timezone" type="string" value=""/>
      <property name="show-seconds" type="bool" value="false"/>
      <property name="digital-time-format" type="string" value=" %Y-%m-%d &lt;b&gt;%H:%M&lt;/b&gt;"/>
      <property name="digital-layout" type="uint" value="3"/>
      <property name="digital-time-font" type="string" value="JetBrains Mono Bold 13"/>
    </property>
    <property name="clipman" type="empty">
      <property name="tweaks" type="empty">
        <property name="never-confirm-history-clear" type="bool" value="true"/>
      </property>
      <property name="settings" type="empty">
        <property name="save-on-quit" type="bool" value="false"/>
        <property name="max-texts-in-history" type="uint" value="5"/>
      </property>
    </property>
    <property name="plugin-20" type="string" value="power-manager-plugin"/>
    <property name="plugin-6" type="string" value="systray">
      <property name="single-row" type="bool" value="true"/>
      <property name="hide-new-items" type="bool" value="false"/>
      <property name="square-icons" type="bool" value="true"/>
      <property name="icon-size" type="int" value="0"/>
      <property name="menu-is-primary" type="bool" value="false"/>
      <property name="symbolic-icons" type="bool" value="false"/>
    </property>
    <property name="plugin-15" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
  </property>
  <property name="configver" type="int" value="2"/>
</channel>'
}

print_tmux_conf() {
    cat << EOL
set-option -g default-shell /usr/bin/fish
set -g default-command /usr/bin/fish

bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"

set -g status off
set -g history-limit 999999999
set -g mouse on

setw -g mode-keys vi

set-option -s set-clipboard off

bind P paste-buffer
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X rectangle-toggle
unbind -T copy-mode-vi Enter
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel 'xclip -se c -i'
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'xclip -se c -i'
EOL
}

download_resources() {
    local TEMP_DIR=`mktemp -d /tmp/xfce.XXXXXXXXXX`
    local FONTS_DIR="$HOME/.fonts"
    local ICONS_DIR="$HOME/.icons"
    local THEMES_DIR="$HOME/.themes"

    local GITHUB_PROJECT_BASE_URL="https://raw.githubusercontent.com/flavien-perier/linux-configuration/master"

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
    sed -i "s/Inherits=.*/Inherits=Papirus/g" $ICONS_DIR/Papirus-Dark/index.theme

    gtk-update-icon-cache $ICONS_DIR/Papirus/
    gtk-update-icon-cache $ICONS_DIR/Papirus-Dark/
    gtk-update-icon-cache $ICONS_DIR/Sweet-Rainbow/

    wget $GITHUB_PROJECT_BASE_URL/icons/flavien.png -O $ICONS_DIR/flavien.png
    wget $GITHUB_PROJECT_BASE_URL/icons/manjaro.png -O $ICONS_DIR/manjaro.png

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

apply_settings_theme() {
    xfconf-query -n -c xfwm4 -p /general/theme -t string -s "Sweet-Dark-v40"
    xfconf-query -n -c xsettings -p /Net/ThemeName -t string -s "Sweet-Dark-v40"
    xfconf-query -n -c xsettings -p /Net/IconThemeName -t string -s "Sweet-Rainbow"
    xfconf-query -n -c xsettings -p /Gtk/CursorThemeName -t string -s "Breeze"

    xfconf-query -n -c xfce4-panel -p /plugins/plugin-5/digital-time-font -t string -s "JetBrains Mono Bold 13"
    xfconf-query -n -c xfce4-terminal -p /font-name -t string -s "JetBrains Mono NL 15"
    xfconf-query -n -c xfwm4 -p /general/title_font -t string -s "JetBrains Mono NL Bold 14"
    xfconf-query -n -c xsettings -p /Gtk/FontName -t string -s "JetBrains Mono NL 13"
    xfconf-query -n -c xsettings -p /Gtk/MonospaceFontName -t string -s "JetBrains Mono NL Light 10"
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
    xfconf-query -n -c xfce4-terminal -p /misc-menubar-default -t bool -s false

    if command_exists "tmux"
    then
        xfconf-query -n -c xfce4-terminal -p /run-custom-command -t bool -s true
        xfconf-query -n -c xfce4-terminal -p /custom-command -t string -s "tmux"
        xfconf-query -n -c xfce4-terminal -p /scrolling-bar -t string -s "TERMINAL_SCROLLBAR_NONE"

        print_tmux_conf > $HOME/.tmux.conf
    fi
}

apply_settings_panel() {
    mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
    print_xfce_pannel_configuration > $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
}

main() {
    download_resources

    apply_settings_theme
    apply_settings_terminal
    # apply_settings_panel
}

main
