#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Install Arch Linux base

set -e

SCRIPT_TITLE="Arch configuration"

print_error() {
    local ERROR_MESSAGE="$1"

    echo "$ERROR_MESSAGE" 1>&2
    whiptail --title "$SCRIPT_TITLE" --msgbox "$ERROR_MESSAGE" 10 50
}

install_menu() {
    local RETRY_PASSWORD
    local RETRY_LUKS_PASSWORD

    if [[ $# -eq 6 ]]
    then
        DISK=$1
        RESET_DISK=$2
        HOSTNAME=$3
        USERNAME=$4
        PASSWORD=$5
        LUKS_PASSWORD=$6
    else
        DISK=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Disk used for install" 10 50 3>&1 1>&2 2>&3)

        if whiptail --title "$SCRIPT_TITLE" --yesno "Format the disk, or reinstall the operating system ?" --yes-button "Format" --no-button "Reset OS" 10 50
        then
            RESET_DISK=1
        else
            RESET_DISK=0
        fi

        HOSTNAME=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Hostname" 10 50 3>&1 1>&2 2>&3)
        USERNAME=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Username" 10 50 3>&1 1>&2 2>&3)

        while true
        do
            PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "Password" 10 50 3>&1 1>&2 2>&3)
            RETRY_PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "Retry Password" 10 50 3>&1 1>&2 2>&3)

            if [[ "$PASSWORD" = "$RETRY_PASSWORD" ]]
            then
                break
            else
                print_error "The passwords are not identical. Please try again."
            fi
        done

        while true
        do
            LUKS_PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "LUKS password" 10 50 3>&1 1>&2 2>&3)
            RETRY_LUKS_PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "Retry LUKS password" 10 50 3>&1 1>&2 2>&3)

            if [[ "$LUKS_PASSWORD" = "$RETRY_LUKS_PASSWORD" ]]
            then
                break
            else
                print_error "The passwords are not identical. Please try again."
            fi
        done
    fi
}

create_partitions() {
    if [[ $DISK == /dev/nvme* ]]
    then
        DISK1=${DISK}p1
        DISK2=${DISK}p2
        DISK3=${DISK}p3
        DISK4=${DISK}p4
    else
        DISK1=${DISK}1
        DISK2=${DISK}2
        DISK3=${DISK}3
        DISK4=${DISK}4
    fi

    if [[ $RESET_DISK -eq 1 ]]
    then
        parted --script $DISK mklabel gpt
        parted --script $DISK mkpart primary 1MiB 501MiB
        parted --script $DISK mkpart primary 501MiB 1001MiB
        parted --script $DISK mkpart primary 1001MiB 9001Mib
        parted --script $DISK mkpart primary 9001Mib 100%

        mkfs.fat -F32 $DISK1
        mkfs.ext4 $DISK2
        mkswap $DISK3

        echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --hash sha256 --batch-mode --key-file=- $DISK4
        echo -n "$LUKS_PASSWORD" | cryptsetup luksOpen --key-file=- $DISK4 system

        mkfs.btrfs -f /dev/mapper/system

        swapon $DISK3

        mount /dev/mapper/system $INSTALL_DIR
        btrfs subvolume create $INSTALL_DIR/@
        btrfs subvolume create $INSTALL_DIR/@home
        btrfs subvolume create $INSTALL_DIR/@log
        btrfs subvolume create $INSTALL_DIR/@cache
        umount $INSTALL_DIR
    else
        mkfs.fat -F32 $DISK1
        mkfs.ext4 $DISK2
        mkswap $DISK3

        echo -n "$LUKS_PASSWORD" | cryptsetup luksOpen --key-file=- $DISK4 system

        mount /dev/mapper/system $INSTALL_DIR
        btrfs subvolume delete -R $INSTALL_DIR/@
        btrfs subvolume create $INSTALL_DIR/@
        btrfs subvolume delete -R $INSTALL_DIR/@cache
        btrfs subvolume create $INSTALL_DIR/@cache
        umount $INSTALL_DIR
    fi
}

mount_partitions() {
    mount -o defaults,discard=async,ssd,subvol=@ /dev/mapper/system $INSTALL_DIR

    mkdir -p $INSTALL_DIR/tmp

    mkdir -p $INSTALL_DIR/var/log
    mount -o defaults,discard=async,ssd,subvol=@log /dev/mapper/system $INSTALL_DIR/var/log

    mkdir -p $INSTALL_DIR/var/cache
    mount -o defaults,discard=async,ssd,subvol=@cache /dev/mapper/system $INSTALL_DIR/var/cache

    mkdir -p $INSTALL_DIR/home
    mount -o defaults,noatime,compress=zstd,space_cache=v2,subvol=@home /dev/mapper/system $INSTALL_DIR/home

    mkdir -p $INSTALL_DIR/boot
    mount $DISK2 $INSTALL_DIR/boot
    mkdir -p $INSTALL_DIR/boot/efi
    mount $DISK1 $INSTALL_DIR/boot/efi
}

install_base_packages() {
    local BASE_PACKAGES="base grub efibootmgr cryptsetup btrfs-progs plymouth systemd networkmanager pacman"

    if [[ "$CD_TYPE" == "arch" ]]
    then
        pacstrap $INSTALL_DIR $BASE_PACKAGES \
            linux \
            linux-firmware \
            pipewire
    elif [[ "$CD_TYPE" == "manjaro" ]]
    then
        pacman-mirrors --fasttrack

        basestrap $INSTALL_DIR $BASE_PACKAGES \
            base-devel \
            linux618 \
            linux618-headers \
            linux-firmware-amdgpu \
            linux-firmware-atheros \
            linux-firmware-broadcom \
            linux-firmware-cirrus \
            linux-firmware-intel \
            linux-firmware-mediatek \
            linux-firmware-meta \
            linux-firmware-nvidia \
            linux-firmware-other \
            linux-firmware-radeon \
            linux-firmware-realtek \
            linux-firmware-whence \
            pacman-mirrors \
            manjaro-system \
            manjaro-keyring \
            manjaro-release \
            manjaro-pipewire \
            manjaro-alsa \
            manjaro-settings-manager \
            mhwd \
            filesystem \
            grub-theme-manjaro \
            plymouth-theme-manjaro
    fi
}

configure_hostname() {
    echo "$HOSTNAME" > $INSTALL_DIR/etc/hostname
}

configure_network() {
    cat << EOL > $INSTALL_DIR/etc/hosts
127.0.0.1 localhost
::1       localhost

127.0.0.1 $HOSTNAME
::1       $HOSTNAME
EOL

    mkdir -p $INSTALL_DIR/etc/NetworkManager/conf.d
    cat << EOL > $INSTALL_DIR/etc/NetworkManager/conf.d/90-dns.conf
[main]
dns=systemd-resolved
EOL

    cat << EOL > $INSTALL_DIR/etc/systemd/resolved.conf
[Resolve]
DNS=208.67.222.222 1.1.1.1 151.80.222.79
FallbackDNS=208.67.220.220 1.0.0.1
EOL

    rm -f $INSTALL_DIR/etc/resolv.conf
    $CHROOT ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    $CHROOT systemctl enable systemd-resolved
    $CHROOT systemctl enable NetworkManager
}

configure_fstab() {
    if [[ "$CD_TYPE" == "arch" ]]
    then
        genfstab -U $INSTALL_DIR >> $INSTALL_DIR/etc/fstab
    elif [[ "$CD_TYPE" == "manjaro" ]]
    then
        fstabgen -U $INSTALL_DIR >> $INSTALL_DIR/etc/fstab
    fi

    echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0" >> $INSTALL_DIR/etc/fstab
}

install_tools() {
    $CHROOT pacman --noconfirm -Sy \
        sudo \
        flatpak \
        tmux \
        openssh \
        xclip \
        wl-clipboard \
        fastfetch \
        inetutils \
        curl \
        wget \
        xz \
        zip \
        unzip \
        binutils \
        blueman \
        bluez \
        bluez-utils

    $CHROOT systemctl enable bluetooth
}


configure_sudo() {
    echo "%sudo	ALL=(ALL:ALL) ALL" >> $INSTALL_DIR/etc/sudoers
    $CHROOT groupadd sudo
}

install_de() {
    $CHROOT pacman --noconfirm -Sy \
        lightdm \
        lightdm-gtk-greeter \
        exo \
        garcon \
        libxfce4ui \
        libxfce4util \
        thunar \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        thunar-volman \
        tumbler \
        xfce4-appfinder \
        xfce4-battery-plugin \
        xfce4-clipman-plugin \
        xfce4-notifyd \
        xfce4-panel \
        xfce4-power-manager \
        xfce4-pulseaudio-plugin \
        xfce4-screenshooter \
        xfce4-session \
        xfce4-settings \
        xfce4-taskmanager \
        xfce4-terminal \
        xfce4-whiskermenu-plugin \
        xfce4-xkb-plugin \
        rio \
        xfconf \
        xfdesktop \
        sway \
        xfwm4 \
        xfwm4-themes \
        libnma \
        network-manager-applet

    $CHROOT systemctl enable lightdm
    $CHROOT systemctl enable seatd

    $CHROOT bash <(curl -Lqs https://sh.flavien.io/desktop.sh) /etc/skel
    sed -i 's|value="flavien"|value="arch"|g' $INSTALL_DIR/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
}

create_user() {
    $CHROOT useradd -m $USERNAME
    $CHROOT usermod -a -G sudo $USERNAME
    echo "$USERNAME:$PASSWORD" | $CHROOT chpasswd

    curl -Lqs https://sh.flavien.io/shell.sh | $CHROOT bash -
}

configure_local() {
    echo "fr_FR.UTF-8 UTF-8" > $INSTALL_DIR/etc/locale.gen
    echo "LANG=fr_FR.UTF-8" > $INSTALL_DIR/etc/locale.conf
    echo "KEYMAP=fr" > $INSTALL_DIR/etc/vconsole.conf
    $CHROOT ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    $CHROOT hwclock --systohc
    $CHROOT locale-gen
    cat << EOL > $INSTALL_DIR/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "fr"
        Option "XkbModel" "pc105"
EndSection
EOL
}

configure_grub() {
    local DISK4_UUID
    DISK4_UUID=$(blkid -s UUID -o value "$DISK4")

    local HOOKS
    local GRUB_CMDLINE_LINUX

    if [[ "$CD_TYPE" == "arch" ]]
    then
        HOOKS="(base udev plymouth autodetect modconf kms keyboard keymap block encrypt btrfs filesystems fsck)"
        GRUB_CMDLINE_LINUX="cryptdevice=UUID=${DISK4_UUID}:system root=/dev/mapper/system rootflags=subvol=@ quiet splash"
    elif [[ "$CD_TYPE" == "manjaro" ]]
    then
        HOOKS="(base systemd autodetect modconf kms keyboard sd-vconsole plymouth block sd-encrypt btrfs filesystems fsck)"
        GRUB_CMDLINE_LINUX="rd.luks.name=${DISK4_UUID}=system root=/dev/mapper/system rootflags=subvol=@ quiet splash"
    fi

    sed -i "s|^HOOKS=.*|HOOKS=$HOOKS|" "$INSTALL_DIR/etc/mkinitcpio.conf"
    sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX\"|" "$INSTALL_DIR/etc/default/grub"
    sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=n/' "$INSTALL_DIR/etc/default/grub"

    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$INSTALL_DIR/etc/default/grub"

    $CHROOT mkinitcpio -P
    $CHROOT grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="$CD_TYPE-linux" --recheck
    $CHROOT grub-mkconfig -o /boot/grub/grub.cfg
}

main() {
    # Check if running as root
    if [[ "$EUID" -ne 0 ]]
    then
        print_error "This script must be run as root"
        exit 1
    fi

    INSTALL_DIR="$(mktemp -d -p /mnt install.XXX)"

    if grep -q "ID=arch" /etc/os-release
    then
        CD_TYPE="arch"
        CHROOT="arch-chroot $INSTALL_DIR"
    elif grep -q "ID=manjaro" /etc/os-release
    then
        CD_TYPE="manjaro"
        CHROOT="manjaro-chroot $INSTALL_DIR"
    else
        print_error "Unsupported distribution cd"
        exit 1
    fi

    install_menu $*

    ip link
    timedatectl set-ntp true

    # Update keyring and CA certificates to avoid signature and SSL errors
    pacman -Sy --noconfirm archlinux-keyring ca-certificates ca-certificates-utils

    create_partitions
    mount_partitions
    install_base_packages
    configure_hostname
    configure_network
    configure_fstab
    install_tools
    configure_sudo
    install_de
    create_user
    configure_local
    configure_grub
}

main $*
