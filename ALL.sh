
cd $( dirname $0 )

SET_X=""
SET_X="-e SET_X=1"

SCRIPT_DIR=$PWD/build-scripts/
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
    CMD="$SCRIPT_DIR/build-docker-image.sh $SET_X"
    echo "-- $CMD"
    $CMD || die "build-docker-image.sh failed"
}

ABOUT_TO "About to rebuild ISO Image" && {
    CMD="$SCRIPT_DIR/build-iso-image.sh $SET_X"
    echo "-- $CMD"
    $CMD || die "build-iso-image.sh failed"
}

ABOUT_TO "About to check ISO is bootable [UEFI mode] ... " && {
    CMD="$SCRIPT_DIR/check-image-bootable.sh -uefi-iso"
    echo "-- $CMD"
    $CMD || die "check-image-bootable.sh -uefi-iso failed"
}

ABOUT_TO "About to write ISO to USB drive ... " && {
    CMD="$SCRIPT_DIR/write-iso-image-to-disk.sh"
    echo "-- $CMD"
    $CMD || die "write-iso-image.sh failed"
}

ABOUT_TO "About to check USB drive is bootable [UEFI mode] ... " && {
    CMD="$SCRIPT_DIR/check-image-bootable.sh -uefi-usb"
    echo "-- $CMD"
    $CMD || die "check-image-bootable.sh -uefi-usb failed"
}


