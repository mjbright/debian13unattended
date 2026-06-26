#!/usr/bin/env bash

DISK=/dev/sdb


ISO_FILE=~/debian-trixie-iso/debian-trixie-unattended.iso
ls -altr  $ISO_FILE
ls -altrh $ISO_FILE

HOST=$(hostname)

die() { echo "$0: die - $*" >&2; exit 1; }

WRITE_DISK() {
    echo; echo "-- Showing Eltorrito entries in iso $ISO_FILE"
    xorriso -indev $ISO_FILE -report_el_torito plain

    read -p "DANGER: type 'yes' to write to '$DISK' ... [no] " DUMMY
    [ "${DUMMY}" != "yes" ] && exit

    #DD_CMD="dd ibs=1k if=$ISO_FILE of=$DISK status=progress"
    # sudo dd if=output/debian-trixie-unattended.iso of=/dev/sdX bs=4M status=progress
    DD_CMD="dd bs=4M if=$ISO_FILE of=$DISK status=progress"

    echo; echo "-- WARNING: about to overwrite disk $DISK:"
    echo "-- CMD='$DD_CMD'"
    read -p "Press <enter> to continue"

    sudo ~/scripts/time.py $DD_CMD
    # sudo dd ibs=1k if=~/debian-trixie-iso/debian-trixie-unattended.iso of=/dev/sdb
}

MACOS_DISK_LIST() {
    echo; echo "-- Searching for external physical disks:"
    diskutil list | grep -A 3  -E "^/dev/.* \(external, physical):"

    DISK=$( diskutil list | grep -m1 -E "^/dev/.* \(external, physical):" | awk '{ print $1; }' )
    [ -z "$DISK" ] && die "Failed to find suitable device"
    echo "-- DONE Searching"

    echo "[sanity check] Double checking only 1 external,physical disk found:"
    EXT_PHYS_DRIVE_COUNT=$( diskutil list | grep -c '/dev/disk[0-9] .external, physical' )
    [ "$EXT_PHYS_DRIVE_COUNT" != "1" ] && die "Failed to find single candidate drive"
}

case $HOST in
    air) #echo "Use rufus or other to write iso to USB key";;
        echo "[air] HOST='$HOST'"
        MACOS_DISK_LIST

	DISK=/dev/disk8
        WRITE_DISK
	;;

      *)
        echo "[*] HOST='$HOST'"
        sudo fdisk -l $DISK
        WRITE_DISK
	;;
esac

