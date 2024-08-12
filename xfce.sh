#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Configure XFCE

set -e

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

apply_xfce_settings() {
    
}

backup_actual_xfce_configuration