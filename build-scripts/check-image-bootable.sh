
#MEM=512
MEM=2048

# Deepseek: to avoid occasional problems switching between Linux virtual consoles in macOs:
# - append the following to qemu commands
# - give permissions to Qemu: System Settings > Privacy & Security > Accessibility.
MACOS_KEY_GRAB="-display cocoa,full-grab=on"

# Deepseek: Try to influence for QEMU via SMBIOS
# Note:
# - setting of device to eno1 not working (use of -smbios prevents Qemu graphics for some reason)
# - setting of MAXC address is working, note that IP will be on 10.0.2.0/24 subnet (probably)
NETDEV=enp1s0
NETDEV=net0 # to "force" to eno1
QEMU_MAC=52:54:00:12:34:56
# NETWORK_ARGS="-netdev user,id=$NETDEV -device virtio-net-pci,netdev=$NETDEV,mac=$QEMU_MAC -smbios type=41,designation=OnboardLAN,instance=1,kind=ethernet,pcidev=$NETDEV"
NETWORK_ARGS="-netdev user,id=$NETDEV,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=$NETDEV,mac=$QEMU_MAC"
# Deepseek: hostfwd=tcp:2222-:22 allows to ssh to localhost on port 2222


# Deepseek: Apple Silicon / x86 emulation:
#     Since you’re using TCG (software emulation), disk I/O will be slow.
#     Use small disk (e.g. 2 GB) for testing, & consider -accel tcg (default)
#     – it’s the only option for x86_64 on M1.
#     The installer will take a while to format and copy packages,
#     but it’s fine for validation.
ACCEL_TCG="-accel tcg"

MACOS_OPTS="$ACCEL_TCG $MACOS_KEY_GRAB"

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

    [ $COPY -eq 0 ] && {
	echo "$TMP_ISO_FILE exists - checking if it needs to be updated or not ... [ based on sizes ]"
	SIZE_TMP_ISO=$(  wc -c $TMP_ISO_FILE | awk '{ print $1; }' )
	SIZE_ISO=$(      wc -c $ISO_FILE | awk '{ print $1; }' )

	[ "$SIZE_TMP_ISO" != "$SIZE_ISO" ] && COPY=1
    
    }

    CHECK_CKSUM=0
    [ $CHECK_CKSUM -ne 0 ] && [ -s $TMP_ISO_FILE ] && {
	echo "$TMP_ISO_FILE exists - checking if it needs to be updated or not ... [ based on cksums ]"
        CKSUM0=$( cksum < $ISO_FILE )
        CKSUM1=$( cksum < $TMP_ISO_FILE )

        [ "$CKSUM0" != "$CKSUM1" ] && {
            COPY=1
            echo "Iso files differ"
        }
    }

    [ $COPY -ne 0 ] && {
        # Deepseek: The /tmp directory on macOS is a memory‑backed filesystem that often has relaxed locking. Copy the ISO there and boot from that copy:
	echo; echo "Copying iso file to /tmp to avoid locking problems"
        echo "Copying $ISO_FILE to $TMP_ISO_FILE"
        #set -x; cp $ISO_FILE $TMP_ISO_FILE
        set -x; rsync -av $ISO_FILE $TMP_ISO_FILE --progress
    }

    # Create empty file:
    #touch /tmp/edk2-x86_64-vars.fd
    # Create "empty" file:
    dd if=/dev/zero of=/tmp/edk2-x86_64-vars.fd bs=1K count=528 2>/dev/null

    QEMU_WITH_VDISK=0
    QEMU_WITH_VDISK=1

    if [ $QEMU_WITH_VDISK -eq 0 ]; then
      # Without virtual disk:
      echo; echo "[BOOT_UEFI_ISO] Booting [w/o virtual disk] ..."
      set -x
        qemu-system-x86_64 -m $MEM -cdrom $TMP_ISO_FILE -boot d -drive if=pflash,format=raw,file=/opt/homebrew/opt/qemu/share/qemu/edk2-x86_64-code.fd,readonly=on -drive if=pflash,format=raw,file=/tmp/edk2-x86_64-vars.fd \
         $MACOS_OPTS \
	 $NETWORK_ARGS

      set +x
    else
      # With virtual disk:
      echo; echo "[BOOT_UEFI_ISO] Booting [with virtual disk] ..."
      VDISK=/tmp/vdisk.qcow2
      VDISK=/tmp/vdisk.img
      VDISK_SIZE=2G
      case $VDISK in
          *.img)   VDISK_FORMAT=raw;   qemu-img create -f $VDISK_FORMAT $VDISK 10G;;
          *.qcow2) VDISK_FORMAT=qcow2; qemu-img create -f $VDISK_FORMAT $VDISK 10G;;
      esac

      VDISK_OPTS="-drive file=$VDISK,format=$VDISK_FORMAT,if=none,id=nvme0 -device nvme,serial=deadbeef,drive=nvme0"

      set -x
        qemu-system-x86_64 -m $MEM -cdrom $TMP_ISO_FILE -boot d -drive if=pflash,format=raw,file=/opt/homebrew/opt/qemu/share/qemu/edk2-x86_64-code.fd,readonly=on -drive if=pflash,format=raw,file=/tmp/edk2-x86_64-vars.fd $VDISK_OPTS \
         $MACOS_OPTS \
	 $NETWORK_ARGS
      set +x

    fi
}

BOOT_UEFI_USB() {
    diskutil list | grep -A 3 -E "^/dev/.* \(external, physical):"
    DRIVE=$( diskutil list | grep -m1 -E "^/dev/.* \(external, physical):" | awk '{ print $1; }' )

    echo; echo "[BOOT_UEFI_USB] Using DRIVE=$DRIVE"
    #diskutil list

    set -x
    diskutil unmountDisk $DRIVE

    # Create empty file:
    touch /tmp/edk2-x86_64-vars.fd

    echo "[BOOT_UEFI_USB] Booting ..."
    sudo qemu-system-x86_64 -m 2048 \
        -drive file=$DRIVE,format=raw,if=ide \
        -boot d \
        -drive if=pflash,format=raw,file=/opt/homebrew/opt/qemu/share/qemu/edk2-x86_64-code.fd,readonly=on \
        -drive if=pflash,format=raw,file=/tmp/edk2-x86_64-vars.fd \
         $MACOS_OPTS \
	 $NETWORK_ARGS
    set +x
}

[ -z "$1" ] && set -- -uefi-iso

case "$1" in
    -bi|-bios-iso) BOOT_BIOS_ISO;;
    -i|-uefi-iso) BOOT_UEFI_ISO;;
    -bu|-bios-usb) die "TODO: BOOT_BIOS_USB"; BOOT_BIOS_USB;;
    -u|-uefi-usb) BOOT_UEFI_USB;;
esac


