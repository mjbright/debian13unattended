
#MEM=512
MEM=2048

# Complains about init:
# - qemu-system-x86_64 -boot d -drive file=~/debian-trixie-iso/debian-trixie-unattended.iso
#
set -x
qemu-system-x86_64 -boot d -cdrom ~/debian-trixie-iso/debian-trixie-unattended.iso -m $MEM
