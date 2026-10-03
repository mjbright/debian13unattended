#!/usr/bin/env bash

BOOT_PART=$( mount | grep /boot | awk '{ print $1; }' )

echo "TODO: Determine root device to overwrite boot sector (not boot partition)"
read -p 'About to overwrite boot sector'
dd ibs=1k count=1 if=/dev/zero of=$BOOT_PART

read -p 'About to shutdown"
shutdown -h 0


