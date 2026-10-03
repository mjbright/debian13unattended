
cd $( dirname $0 )

PROMPTS=1

SET_X=""
SET_X="-e SET_X=1"

SCRIPT_DIR=$PWD/build-scripts/
echo "SCRIPT_DIR='$SCRIPT_DIR'"

die() { echo "$0: die - $*" >&2; exit 1; }

ABOUT_TO() {
    DEFAULT=$1; shift
    PROMPT=$*;  set --

    if [ $PROMPTS -eq 0 ]; then
	DUMMY=$DEFAULT
    else
        echo; read -p "${PROMPT} ['s' to skip] [default='$DEFAULT'] ... " DUMMY
        [ "${DUMMY,,}" = ""     ] && DUMMY=$DEFAULT
    fi
    [ "${DUMMY,,}" = "q"    ] && { echo "Skipping/Exiting step ['$PROMPT'] ...";       exit;     }
    [ "${DUMMY,,}" = "s"    ] && { echo "Skipping step ['$PROMPT'] ..."; return 1; }
    [ "${DUMMY,,}" = "no"   ] && { echo "Skipping step ['$PROMPT'] ..."; return 1; }

    [ "${DUMMY,,}" != "yes" ] && { echo "Skipping step ['$PROMPT'] ..."; return 1; }

    # Perform step:
    echo "-->  Performing step:"
    return 0
}

[ "$1" = "-np" ] && PROMPTS=0

ABOUT_TO yes "About to rebuild Docker Image" && {
    CMD="$SCRIPT_DIR/build-docker-image.sh $SET_X"
    echo "-- $CMD"
    ./time.py $CMD || die "build-docker-image.sh failed"
}

ABOUT_TO yes "About to rebuild ISO Image" && {
    CMD="$SCRIPT_DIR/build-iso-image.sh $SET_X"
    echo "-- $CMD"
    ./time.py $CMD || die "build-iso-image.sh failed"
}

ABOUT_TO no "About to check ISO is bootable [UEFI mode] ... " && {
    CMD="$SCRIPT_DIR/check-image-bootable.sh -uefi-iso"
    echo "-- $CMD"
    ./time.py $CMD || die "check-image-bootable.sh -uefi-iso failed"
}

ABOUT_TO yes "About to write ISO to USB drive ... " && {
    CMD="$SCRIPT_DIR/write-iso-image-to-disk.sh"
    echo "-- $CMD"
    ./time.py $CMD || die "write-iso-image.sh failed"
}

ABOUT_TO no "About to check USB drive is bootable [UEFI mode] ... " && {
    CMD="$SCRIPT_DIR/check-image-bootable.sh -uefi-usb"
    echo "-- $CMD"
    ./time.py $CMD || die "check-image-bootable.sh -uefi-usb failed"
}

