
MACOS_DISK_LIST() {
    set -x
    diskutil list | grep -A 3  -E "^/dev/.* \(external, physical):"
    #diskutil list
}

MACOS_DISK_LIST

