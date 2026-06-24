
#MEM=512
MEM=2048

die() { echo "$0: die - $*" >&2; exit 1; }

ISO_FILE=~/debian-trixie-iso/debian-trixie-unattended.iso
[ ! -f $ISO_FILE ] && die "No such iso file as '$ISO_FILE'"
[ ! -s $ISO_FILE ] && die "Empty   iso file    '$ISO_FILE'"


# Complains about init:
# - qemu-system-x86_64 -boot d -drive file=~/debian-trixie-iso/debian-trixie-unattended.iso
# OK: for BIOS Boot:
# - sudo qemu-system-x86_64 -m 2048 -cdrom ~/debian-trixie-iso/debian-trixie-unattended.iso -boot d

lsof $ISO_FILE | grep $ISO_FILE &&
    die "IS_FILE is locked, first kill process with lock ..."

BOOT_BIOS_ISO() {
    echo "BOOT_BIOS_ISO: ..."
    set -x; qemu-system-x86_64 -boot d -cdrom $ISO_FILE -m $MEM; set +x
}

BOOT_UEFI_ISO() {
    echo "BOOT_UEFI_ISO: ..."
    TMP_ISO_FILE=/tmp/$( basename $ISO_FILE )

    # Note: copy logic was necessary to avoid sudo/locking:
    # - https://chat.deepseek.com/a/chat/s/0398efd6-7acd-4b59-b612-8667dc380b0d
    #   "Boot your ISO with UEFI (no sudo, no lock issues)"
    COPY=0
    [ ! -f $TMP_ISO_FILE ] && { COPY=1; echo "No    $TMP_ISO_FILE"; }
    [ ! -s $TMP_ISO_FILE ] && { COPY=1; echo "Empty $TMP_ISO_FILE"; }

    [ -s $TMP_ISO_FILE ] && {
	echo "$TMP_ISO_FILE exists - checking if it needs to be updated or not ..."
        CKSUM0=$( cksum < $ISO_FILE )
        CKSUM1=$( cksum < $TMP_ISO_FILE )

        [ "$CKSUM0" != "$CKSUM1" ] && {
            COPY=1
            echo "Iso files differ"
        }
    }

    [ $COPY -ne 0 ] && {
        echo "Copying $ISO_FILE to $TMP_ISO_FILE"
        #set -x; cp $ISO_FILE $TMP_ISO_FILE
        set -x; rsync -av $ISO_FILE $TMP_ISO_FILE --progress
    }

    # Create empty file:
    touch /tmp/edk2-x86_64-vars.fd
    set -x; qemu-system-x86_64 -m $MEM -cdrom $TMP_ISO_FILE -boot d -drive if=pflash,format=raw,file=/opt/homebrew/opt/qemu/share/qemu/edk2-x86_64-code.fd,readonly=on -drive if=pflash,format=raw,file=/tmp/edk2-x86_64-vars.fd
}

BOOT_UEFI_USB() {
    diskutil list | grep -A 3 -E "^/dev/.* \(external, physical):"
    DRIVE=$( diskutil list | grep -m1 -E "^/dev/.* \(external, physical):" | awk '{ print $1; }' )

    echo "Using DRIVE=$DRIVE"
    #diskutil list

    set -x
    diskutil unmountDisk $DRIVE

    # Create empty file:
    touch /tmp/edk2-x86_64-vars.fd

    sudo qemu-system-x86_64 -m 2048 \
        -drive file=$DRIVE,format=raw,if=ide \
        -boot d \
        -drive if=pflash,format=raw,file=/opt/homebrew/opt/qemu/share/qemu/edk2-x86_64-code.fd,readonly=on \
        -drive if=pflash,format=raw,file=/tmp/edk2-x86_64-vars.fd \
        -accel tcg
    set +x
}

[ -z "$1" ] && set -- -uefi-iso

case "$1" in
    -bios-iso) BOOT_BIOS_ISO;;
    -uefi-iso) BOOT_UEFI_ISO;;
    -bios-usb) die "TODO: BOOT_BIOS_USB"; BOOT_BIOS_USB;;
    -uefi-usb) BOOT_UEFI_USB;;
esac


