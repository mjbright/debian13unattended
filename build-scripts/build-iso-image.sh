
cd $( dirname $0 )
SCRIPT_DIR=$PWD
echo "SCRIPT_DIR='$SCRIPT_DIR'"

cd
pwd

LOG=/tmp/debian-trixie-install.run.log

mkdir -p debian-trixie-iso

die() { echo "$0: die - $*" >&2; exit 1; }

{
    docker run --rm --privileged -v $HOME/debian-trixie-iso:/output debian-trixie-installer
    RET=$?
    [ $RET -ne 0 ] && die "[return code=$RET] docker run failed: to build iso image"
    #[ $RET -ne 0 ] && echo "NEVER GET HERE"
} |& tee $LOG

# Need to check for error message in $LOG, as subprocess created for { block } above due to pipe to tee:
grep -q "docker run failed: to build iso image" $LOG &&
    exit 0
                            #-v $(pwd)/output:/output \
ls -altrh debian-trixie-iso
echo "LOG written to $LOG"

