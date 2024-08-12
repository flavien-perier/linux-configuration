#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Install Arch Linux base

set -e
set -x

SCRIPT_TITLE="Arch configuration"
INSTALL_DIR="/mnt"

loadkeys fr

if [ $# -eq 4 ]
then
    HOSTNAME=$1
    DISK=$2
    USERNAME=$3
    PASSWORD=$4
else
    HOSTNAME=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Hostname" 10 50 3>&1 1>&2 2>&3)
    DISK=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Disk used for install" 10 50 3>&1 1>&2 2>&3)
    USERNAME=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Username" 10 50 3>&1 1>&2 2>&3)
    PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "Password" 10 50 3>&1 1>&2 2>&3)
fi

parted --script $DISK mklabel gpt
parted --script $DISK mkpart primary 1MiB 501MiB
parted --script $DISK mkpart primary 501MiB 4501Mib
parted --script $DISK mkpart primary 4501Mib 100%

ip link
timedatectl set-ntp true

mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
yes | mkfs.ext4 ${DISK}3

swapon ${DISK}2
mount ${DISK}3 $INSTALL_DIR

pacstrap $INSTALL_DIR base linux linux-firmware grub efibootmgr systemd networkmanager sudo pacman flatpak

echo "$HOSTNAME" > $INSTALL_DIR/etc/hostname

# Local configuration
echo "fr_FR.UTF-8 UTF-8" > $INSTALL_DIR/etc/locale.gen
echo "LANG=fr_FR.UTF-8" > $INSTALL_DIR/etc/locale.conf
echo "KEYMAP=fr" > $INSTALL_DIR/etc/vconsole.conf
arch-chroot $INSTALL_DIR ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot $INSTALL_DIR hwclock --systohc
arch-chroot $INSTALL_DIR locale-gen

curl -s https://blackarch.org/strap.sh | arch-chroot $INSTALL_DIR bash -

# Network configuration
cat << EOL > $INSTALL_DIR/etc/hosts
127.0.0.1 localhost
::1       localhost

127.0.0.1 $HOSTNAME
::1       $HOSTNAME
EOL

cat << EOL | sudo tee $INSTALL_DIR/etc/NetworkManager/conf.d/90-dns.conf
[main]
dns=none
EOL

cat << EOL > $INSTALL_DIR/etc/resolv.conf
nameserver 208.67.222.222
nameserver 208.67.220.220
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 151.80.222.79
EOL
arch-chroot $INSTALL_DIR systemctl enable NetworkManager

# Fstab configuration
mkdir -p $INSTALL_DIR/boot/efi
arch-chroot $INSTALL_DIR mount ${DISK}1 /boot/efi
genfstab -U $INSTALL_DIR >> $INSTALL_DIR/etc/fstab

# Sudo configuration
echo "%sudo	ALL=(ALL:ALL) ALL" >> $INSTALL_DIR/etc/sudoers
arch-chroot $INSTALL_DIR groupadd sudo

# User configuration
arch-chroot $INSTALL_DIR useradd -m $USERNAME
arch-chroot $INSTALL_DIR usermod -a -G sudo $USERNAME
curl -s https://sh.flavien.io/shell.sh | arch-chroot $INSTALL_DIR bash -
yes "$USERNAME:$PASSWORD" | arch-chroot $INSTALL_DIR chpasswd

# DE configuration
arch-chroot $INSTALL_DIR pacman --noconfirm -Sy lightdm lightdm-gtk-greeter xfce4 xfce4-goodies
arch-chroot $INSTALL_DIR systemctl enable lightdm

# Grub installation
arch-chroot $INSTALL_DIR grub-install ${DISK} --force
arch-chroot $INSTALL_DIR grub-mkconfig -o /boot/grub/grub.cfg
