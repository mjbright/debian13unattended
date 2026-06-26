#!/usr/bin/env bash
#!/bin/bash
set -e

set -x

# TIMEOUT_SECS => seconds:
TIMEOUT_SECS=1    # Short Menu
TIMEOUT_SECS=10   # Long Menu
TIMEOUT_SECS=0    # No Menu -> boot directly to unattended install

# ALLOW 1 second delay: (possibility to interrupt):
TIMEOUT_SECS=1

let TIMEOUT_ISOLINUX=10*TIMEOUT_SECS
let TIMEOUT_GRUB=TIMEOUT_SECS

# Set timeout to 1 second (10 deciseconds) for automatic boot
## Initial version using genisoimage & isobybrid
## BUT this will produce an (UEFI) unbootable USB drive
## - ISO is bootable by qemu (will use legacy BIOS)
## - h/w USB is not bootable (because although UEFI files present, only a single ElTorrito entry is present for BIOS, not UEFI)
##
## See Deepseek here:
## - https://chat.deepseek.com/a/chat/s/0398efd6-7acd-4b59-b612-8667dc380b0d

echo "===================================="
echo "Debian Trixie Unattended Installer"
echo "===================================="

# Variables
# Using Trixie (testing) netinst ISO
ISO_URL="https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso"
ISO_NAME="debian-netinst.iso"
OUTPUT_ISO="debian-trixie-unattended.iso"
WORK_DIR="/build/work"
MOUNT_DIR="/build/mount"

echo "Creating working directories..."
mkdir -p "$WORK_DIR"
mkdir -p "$MOUNT_DIR"

echo
echo "[$(date)] Downloading Debian netinst ISO..."
BEFORE=$SECONDS

# Use /output if mounted, download iso to /output/initial unless iso already present there:
WGET_DIR="/build"
if [ -d "/output" ]; then
    mkdir -p "/output/initial"
    WGET_DIR="/output/initial"
fi

set -x
echo "Checking if iso present at '$WGET_DIR/$ISO_NAME'"
if [ ! -f "$WGET_DIR/$ISO_NAME" ]; then
    BEFORE=$SECONDS
    echo "Downloading ISO ..."
    wget -qO "$WGET_DIR/$ISO_NAME" "$ISO_URL"
    echo "Here dnld"
    AFTER=$SECONDS
    let TOOK=AFTER-BEFORE
    echo "[$(date)] Download took $TOOK secs"
    echo
else
    echo "ISO already downloaded, skipping..."
fi

ls -altrh "$WGET_DIR/$ISO_NAME"

echo "Mounting ISO..."
mount -o loop "$WGET_DIR/$ISO_NAME" "$MOUNT_DIR"

echo "Copying ISO contents..."
set -x; rsync -av "$MOUNT_DIR/" "$WORK_DIR/" >/tmp/rsync.log 2>&1; set +x
wc -l /tmp/rsync.log

echo "Unmounting ISO..."
umount "$MOUNT_DIR"

echo "Making working directory writable..."
chmod -R +w "$WORK_DIR"

echo "Copying preseed configuration..."
cp /build/preseed.cfg "$WORK_DIR/preseed.cfg"

echo "Copying additional scripts..."
mkdir -p "$WORK_DIR/additional-scripts"
if [ -d "/build/additional-scripts" ] && [ "$(ls -A /build/additional-scripts)" ]; then
    cp -r /build/additional-scripts/* "$WORK_DIR/additional-scripts/"
fi

echo "Modifying isolinux configuration for auto-install..."

# Create custom menu entry for automated install
cat > "$WORK_DIR/isolinux/txt.cfg" << 'EOF'
default auto
label auto
    menu label ^Automated Install
    menu default
    kernel /install.amd/vmlinuz
    append auto=true priority=critical vga=788 initrd=/install.amd/initrd.gz preseed/file=/cdrom/preseed.cfg --- quiet
EOF
wc -l "$WORK_DIR/isolinux/txt.cfg"

echo "Updating main isolinux.cfg to set default(auto) & timeout($TIMEOUT_ISOLINUX 1/10th secs)"
# Set timeout to 1 second (10 deciseconds) for automatic boot
sed -i "s/timeout 0/timeout $TIMEOUT_ISOLINUX/" "$WORK_DIR/isolinux/isolinux.cfg"
# Set the default to auto if not already set
if ! grep -q "^default " "$WORK_DIR/isolinux/isolinux.cfg"; then
    sed -i '1i default auto' "$WORK_DIR/isolinux/isolinux.cfg"
else
    sed -i 's/^default .*/default auto/' "$WORK_DIR/isolinux/isolinux.cfg"
fi

echo; echo "-- [BEG] isolinux.cfg content: ------------------------------------------------------------"
set -x; cat "$WORK_DIR/isolinux/isolinux.cfg"
echo "-- [END] isolinux.cfg content: ------------------------------------------------------------"

set -x; find $WORK_DIR/ -name grub.cfg; set +x

#GRUB_CFG=$WORK_DIR/EFI/BOOT/grub.cfg <<EOF
GRUB_CFG=$WORK_DIR/boot/grub/grub.cfg

cat >$GRUB_CFG <<EOF
set default="unattended"
set timeout=$TIMEOUT_GRUB

menuentry "Unattended Install" --id unattended {
    linux /install.amd/vmlinuz auto=true preseed/file=/cdrom/preseed.cfg ---
    initrd /install.amd/initrd.gz
}
EOF

echo; echo "-- [BEG] grub.cfg content: ------------------------------------------------------------"
set -x; cat "$GRUB_CFG"; set +x
echo "-- [END] grub.cfg content: ------------------------------------------------------------"

echo "Fixing MD5 checksums..."
cd "$WORK_DIR"
chmod +w md5sum.txt
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
chmod -w md5sum.txt

echo "Creating new ISO..."
cd /build
genisoimage -r -J -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o "$OUTPUT_ISO" "$WORK_DIR" \
    > /tmp/genisoimage.log 2>&1
set -x; wc -l /tmp/genisoimage.log; set +x

# Make the ISO bootable
# v1: BIOS only (on physical h/w):
#  isohybrid "$OUTPUT_ISO" || echo "Warning: isohybrid not available, ISO may not be bootable on USB"

# v2: BIOS or UEFI (on physical h/w):
xorriso -as mkisofs \
    -r -J -joliet-long \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -partition_offset 16 \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$OUTPUT_ISO" "$WORK_DIR" \
    > /tmp/xorriso.log 2>&1
set -x; wc -l /tmp/xorriso.log; set +x

echo "===================================="
echo "ISO created successfully: $OUTPUT_ISO"
echo "===================================="

# Copy to output if mounted
if [ -d "/output" ]; then
    cp "$OUTPUT_ISO" "/output/"
    echo "ISO copied to /output/"
fi

echo "Done!"

# Checks proposed by DeepSeek:
#
apt-get update
apt-get install -y fdisk genisoimage
echo; echo "-- Check if isohybrid added a partition table"
fdisk -l $OUTPUT_ISO

echo; echo "-- Check the ISO’s boot catalog (look for UEFI entries)"
isoinfo -d -i $OUTPUT_ISO

echo; echo "-- List the contents of the EFI directory (should exist for UEFI)"
isoinfo -f -i $OUTPUT_ISO | grep -i efi

