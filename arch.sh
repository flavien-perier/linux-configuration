#!/bin/sh
# Flavien PERIER <perier@flavien.io>
# Install Arch Linux base

set -e
set -x

SCRIPT_TITLE="Arch configuration"
INSTALL_DIR="/mnt"

if [ $# -eq 5 ]
then
    HOSTNAME=$1
    DISK=$2
    USERNAME=$3
    PASSWORD=$4
    LUKS_PASSWORD=$5
else
    HOSTNAME=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Hostname" 10 50 3>&1 1>&2 2>&3)
    DISK=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Disk used for install" 10 50 3>&1 1>&2 2>&3)
    USERNAME=$(whiptail --title "$SCRIPT_TITLE" --inputbox "Username" 10 50 3>&1 1>&2 2>&3)
    PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "Password" 10 50 3>&1 1>&2 2>&3)
    LUKS_PASSWORD=$(whiptail --title "$SCRIPT_TITLE" --passwordbox "LUKS password" 10 50 3>&1 1>&2 2>&3)
fi

ip link
timedatectl set-ntp true

# Creating disk partitions
parted --script $DISK mklabel gpt
parted --script $DISK mkpart primary 1MiB 501MiB
parted --script $DISK mkpart primary 501MiB 1001MiB
parted --script $DISK mkpart primary 1001MiB 9001Mib
parted --script $DISK mkpart primary 9001Mib 100%

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

# Update keyring and CA certificates to avoid signature and SSL errors
pacman -Sy --noconfirm archlinux-keyring ca-certificates ca-certificates-utils

# Install base packages
pacstrap $INSTALL_DIR base linux linux-firmware grub efibootmgr cryptsetup btrfs-progs plymouth systemd networkmanager sudo pacman flatpak

echo "$HOSTNAME" > $INSTALL_DIR/etc/hostname

# Network configuration
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

cat << EOL > /etc/systemd/resolved.conf
[Resolve]
DNS=208.67.222.222 1.1.1.1 151.80.222.79
FallbackDNS=208.67.220.220 1.0.0.1
EOL

rm -f $INSTALL_DIR/etc/resolv.conf
arch-chroot $INSTALL_DIR ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

arch-chroot $INSTALL_DIR systemctl enable systemd-resolved
arch-chroot $INSTALL_DIR systemctl enable NetworkManager

# Fstab configuration
genfstab -U $INSTALL_DIR >> $INSTALL_DIR/etc/fstab
echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0" >> $INSTALL_DIR/etc/fstab

# Sudo configuration
echo "%sudo	ALL=(ALL:ALL) ALL" >> $INSTALL_DIR/etc/sudoers
arch-chroot $INSTALL_DIR groupadd sudo

# Aditional tools installation
arch-chroot $INSTALL_DIR pacman --noconfirm -Sy \
    tmux \
    xclip \
    wl-clipboard \
    fastfetch \
    inetutils \
    code \
    curl \
    wget \
    xz \
    zip \
    unzip

# DE installation
arch-chroot $INSTALL_DIR pacman --noconfirm -Sy \
    lightdm \
    pulseaudio \
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
    xfwm4-themes

arch-chroot $INSTALL_DIR systemctl enable lightdm
arch-chroot $INSTALL_DIR systemctl enable seatd

# DE configuration
arch-chroot $INSTALL_DIR bash <(curl -Lqs https://sh.flavien.io/xfce.sh) /etc/skel
sed -i 's|value="flavien"|value="arch"|g' $INSTALL_DIR/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# Local configuration
echo "fr_FR.UTF-8 UTF-8" > $INSTALL_DIR/etc/locale.gen
echo "LANG=fr_FR.UTF-8" > $INSTALL_DIR/etc/locale.conf
echo "KEYMAP=fr" > $INSTALL_DIR/etc/vconsole.conf
arch-chroot $INSTALL_DIR ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot $INSTALL_DIR hwclock --systohc
arch-chroot $INSTALL_DIR locale-gen
cat << EOL > $INSTALL_DIR/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "fr"
        Option "XkbModel" "pc105"
EndSection
EOL

# User configuration
curl -Lqs https://sh.flavien.io/shell.sh | arch-chroot $INSTALL_DIR bash -

arch-chroot $INSTALL_DIR useradd -m $USERNAME
arch-chroot $INSTALL_DIR usermod -a -G sudo $USERNAME
echo "$USERNAME:$PASSWORD" | arch-chroot $INSTALL_DIR chpasswd

# Grub installation

DISK4_UUID=$(blkid -s UUID -o value $DISK4)

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont plymouth encrypt btrfs filesystems fsck)/' $INSTALL_DIR/etc/mkinitcpio.conf
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${DISK4_UUID}:system root=/dev/mapper/system rootflags=subvol=@ quiet splash\"|" $INSTALL_DIR/etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> $INSTALL_DIR/etc/default/grub

arch-chroot $INSTALL_DIR mkinitcpio -P
arch-chroot $INSTALL_DIR grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
arch-chroot $INSTALL_DIR grub-mkconfig -o /boot/grub/grub.cfg
