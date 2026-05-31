#!/usr/bin/env bash

DISK=/dev/sdb

sudo fdisk -l $DISK

echo; echo "-- WARNING: about to overwrite disk $DISK:"
read -p "Press <enter> to continue"

IF=~/debian-trixie-iso/debian-trixie-unattended.iso
ls -altr $IF

case $(hostname) in
    air) echo "Use rufus or other to write iso to USB key";;

      *) sudo ~/scripts/time.py dd ibs=1k if=$IF of=$DISK
         # sudo dd ibs=1k if=~/debian-trixie-iso/debian-trixie-unattended.iso of=/dev/sdb
	 ;;
esac



