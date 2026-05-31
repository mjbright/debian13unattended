
cd

mkdir -p debian-trixie-iso

docker run --rm --privileged -v $HOME/debian-trixie-iso:/output debian-trixie-installer
                            #-v $(pwd)/output:/output \
ls -altrh debian-trixie-iso


