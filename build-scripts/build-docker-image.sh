
TAG="debian-trixie-installer"

BUILD_ON_AMD64() {
    echo; echo "BUILD_ON_AMD64: building Docker image $TAG ..."
    set -x; docker build -t $TAG .; set +x
}

BUILD_ON_ARM64() {
    echo; echo "BUILD_ON_ARM64: building Docker image $TAG ..."
    set -x; docker buildx create --name mybuilder --use; set +x

    # UNNEEDED NOW: Make "buildx" the default
    #docker buildx install

    # Build for multiple platforms
    #docker build --platform linux/amd64,linux/arm64 -t $TAG .
    # Build for AMD64 platform:
    set -x; docker build --load --platform linux/amd64 -t $TAG .; set +x

    echo "Resulting CMD in image:"
    docker image inspect debian-trixie-installer   | grep -A2 -i cmd

    echo "Resulting files in image:"
    #set -x; docker build --load --platform linux/amd64 -t $TAG --no-cache .; set +x
    docker run --rm -it debian-trixie-installer find
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

