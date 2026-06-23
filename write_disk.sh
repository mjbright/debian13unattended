#!/usr/bin/env bash

DISK=/dev/sdb


ISO_FILE=~/debian-trixie-iso/debian-trixie-unattended.iso
ls -altr  $ISO_FILE
ls -altrh $ISO_FILE

HOST=$(hostname)

WRITE_DISK() {
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
    diskutil list | grep -A 3  -E "^/dev/.* \(external, physical):"
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

