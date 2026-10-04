#!/usr/bin/env bash

DISK=/dev/sdb

ISO_FILE=~/debian-trixie-iso/debian-trixie-unattended.iso
ls -altr  $ISO_FILE
ls -altrh $ISO_FILE

HOST=$(hostname)

## -- Func: --------------------------------------------------------------------------------

die() { echo "$0: die - $*" >&2; exit 1; }

CHECK_PRESEED() {
    echo; echo "---- Checking that preseed.cfg in Docker image is the same as local preseed.cfg.private:"
    cat ./docker.image.build.files.preseed.cfg.cksum
    DOCKER_PRESEED_CKSUM=$( awk '{ print $1; }' < ./docker.image.build.files.preseed.cfg.cksum)
    PRIVATE_PRESEED_CKSUM=$( cksum preseed.cfg.private | awk '{ print $1; }' )
    # 1136337608 5796 /build/preseed.cfg
    # 1136337608 5796 preseed.cfg.private
    [ "$DOCKER_PRESEED_CKSUM" != "$PRIVATE_PRESEED_CKSUM" ] && {
        echo "----"
        echo "DOCKER_PRESEED_CKSUM=$DOCKER_PRESEED_CKSUM"
        echo "PRIVATE_PRESEED_CKSUM=$PRIVATE_PRESEED_CKSUM"
        echo "In Docker image:   $(cat ./docker.image.build.files.preseed.cfg.cksum)"
        echo "Local preseed.cfg: $(cksum preseed.cfg.private)"
        read -p "preseed.cfg in Docker image has different cksum - press <Enter> to continue"
    }
}

WRITE_DISK() {
    echo; echo "-- Showing Eltorrito entries in iso $ISO_FILE"
    xorriso -indev $ISO_FILE -report_el_torito plain

    echo; echo "ISO LABEL:" $( xorriso -indev ~/debian-trixie-iso/debian-trixie-unattended.iso -report_el_torito plain |& grep -i debianpre )

    read -p "DANGER: type 'yes' to write to '$DISK' ... [no] " DUMMY
    echo "DUMMY=$DUMMY"
    [ "${DUMMY}" != "yes" ] && { echo "Skipping writing to disk"; exit; }

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

    # diskutil list $DISK | grep -i DEBIANPRE || die "Selected disk does not have DEBIANPRE label"
    DUMMY="no"
    # diskutil list $DISK | grep -i DEBIANPRE ||
    # diskutil info $DISK | grep -i DEBIANPRE ||
    sudo dd if=/dev/rdisk4 bs=1024 skip=0 count=64  | strings | grep -i debianpre || {
	read -p "Disk $DISK doesn't have label 'DEBIANPRE' - continue? type 'yes'" DUMMY
        [ "${DUMMY,,}" != "yes" ] && exit
    }

    echo "[sanity check] Double checking only 1 external,physical disk found:"
    EXT_PHYS_DRIVE_COUNT=$( diskutil list | grep -c '/dev/disk[0-9] .external, physical' )
    [ "$EXT_PHYS_DRIVE_COUNT" != "1" ] && die "Failed to find single candidate drive"
}

## -- Main: --------------------------------------------------------------------------------

CHECK_PRESEED

case $HOST in
    air) #echo "Use rufus or other to write iso to USB key";;
        echo "[air] HOST='$HOST'"
        MACOS_DISK_LIST
	#DISK=/dev/disk8
	#DISK=/dev/disk4
	#diskutil unmountDisk /dev/disk4
	diskutil unmountDisk $DISK
        WRITE_DISK
	;;

      *)
        echo "[*] HOST='$HOST'"
        sudo fdisk -l $DISK
        WRITE_DISK
	;;
esac

