
#MEM=512
MEM=2048

set -x
qemu-system-x86_64 -boot d -cdrom ~/debian-trixie-iso/debian-trixie-unattended.iso -m $MEM
