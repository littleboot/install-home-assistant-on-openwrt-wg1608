#!/bin/sh
# Expand root storage with sd card.

opkg update
opkg install block-mount kmod-fs-ext4 e2fsprogs parted
parted -s /dev/mmcblk0 -- mklabel gpt mkpart extroot 2048s -2048s

DEVICE="$(sed -n -e "/\s\/overlay\s.*$/s///p" /etc/mtab)"
uci -q delete fstab.rwm
uci set fstab.rwm="mount"
uci set fstab.rwm.device="${DEVICE}"
uci set fstab.rwm.target="/rwm"
uci commit fstab

mkfs.ext4 -L extroot "/dev/mmcblk0"

eval $(block info "/dev/mmcblk0" | grep -o -e "UUID=\S*")
uci -q delete fstab.overlay
uci set fstab.overlay="mount"
uci set fstab.overlay.uuid="${UUID}"
uci set fstab.overlay.target="/overlay"
uci commit fstab

mount "/dev/mmcblk0" /mnt
tar -C /overlay -cvf - . | tar -C /mnt -xf -

echo "Finished rebooting now"
reboot