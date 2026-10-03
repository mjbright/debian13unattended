
set -x
docker run --rm --privileged -v $HOME/debian-trixie-iso:/output  debian-trixie-installer ls -altrR /build/

