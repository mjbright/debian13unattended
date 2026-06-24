
TAG="debian-trixie-installer"

BUILD_ON_AMD64() {
    echo; echo "BUILD_ON_AMD64: building Docker image $TAG ..."
    docker build -t $TAG .
}

BUILD_ON_ARM64() {
    echo; echo "BUILD_ON_ARM64: building Docker image $TAG ..."
    docker buildx create --name mybuilder --use

    # UNNEEDED NOW: Make "buildx" the default
    #docker buildx install

    # Build for multiple platforms
    #docker build --platform linux/amd64,linux/arm64 -t $TAG .
    # Build for AMD64 platform:
    docker build --load --platform linux/amd64 -t $TAG .
}

case $(hostname) in
    air) BUILD_ON_ARM64;;
      *) BUILD_ON_AMD64;;
esac

set -x

mkdir -p  ~/debian-trixie-iso/
ls -altrh ~/debian-trixie-iso/

echo
docker image ls | head -2

