
cd $( dirname $0 )

SET_X=""
SET_X="-e SET_X=1"

SCRIPT_DIR=$PWD
echo "SCRIPT_DIR='$SCRIPT_DIR'"

die() { echo "$0: die - $*" >&2; exit 1; }

ABOUT_TO() {
    PROMPT=$*; set --

    echo; read -p "${PROMPT} ['s' to skip] ... " DUMMY
    [ "${DUMMY,,}" = "q" ] && exit
    [ "${DUMMY,,}" = "s" ] && return 1 # Skip step

    # Perform step:
    echo "-->  Performing step:"
    return 0
}

ABOUT_TO "About to rebuild Docker Image" && {
    CMD="$SCRIPT_DIR/build_docker_image.sh $SET_X"
    echo "-- $CMD"
    $CMD || die "build_docker_image.sh failed"
}

ABOUT_TO "About to rebuild ISO Image" && {
    CMD="$SCRIPT_DIR/build_iso_image.sh $SET_X"
    echo "-- $CMD"
    $CMD || die "build_iso_image.sh failed"
}

ABOUT_TO "About to check ISO is bootable [UEFI mode] ... " && {
    CMD="$SCRIPT_DIR/check_image_bootable.sh -uefi-iso"
    echo "-- $CMD"
    $CMD || die "check_image_bootable.sh -uefi-iso failed"
}

ABOUT_TO "About to write ISO to USB drive ... " && {
    CMD="$SCRIPT_DIR/write_iso_image_to_disk.sh"
    echo "-- $CMD"
    $CMD || die "write_iso_image.sh failed"
}

ABOUT_TO "About to check USB drive is bootable [UEFI mode] ... " && {
    CMD="$SCRIPT_DIR/check_image_bootable.sh -uefi-usb"
    echo "-- $CMD"
    $CMD || die "check_image_bootable.sh -uefi-usb failed"
}


