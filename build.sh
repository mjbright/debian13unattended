
TAG="debian-trixie-installer"

BUILD_ON_AMD64() {
    docker build -t $TAG .
}

BUILD_ON_ARM64() {
    docker buildx create --name mybuilder --use

    # UNNEEDED NOW: Make "buildx" the default
    #docker buildx install

    # Build for multiple platforms
    #docker build --platform linux/amd64,linux/arm64 -t $TAG .
    # Build for AMD64 platform:
    docker build --load --platform linux/amd64 -t $TAG .
}

set -x

case $(hostname) in
    air) BUILD_ON_ARM64;;
      *) BUILD_ON_AMD64;;
esac

mkdir -p  ~/debian-trixie-iso/
ls -altrh ~/debian-trixie-iso/

