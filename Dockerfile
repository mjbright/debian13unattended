FROM debian:trixie-slim
#FROM debian:trixie

# Install necessary tools for building the installer
RUN apt-get update && apt-get install -y \
    wget \
    xorriso \
    isolinux \
    rsync \
    genisoimage \
    syslinux-utils \
    && rm -rf /var/lib/apt/lists/*

# Create working directories
WORKDIR /build

# Create directory for additional scripts
RUN mkdir -p /build/additional-scripts

# Copy preseed configuration
COPY preseed.cfg.private /build/preseed.cfg

# Copy additional scripts directory
COPY additional-scripts/ /build/additional-scripts/

# Copy build script
COPY under-docker-build-installer.sh /build/under-docker-build-installer.sh
RUN chmod +x /build/under-docker-build-installer.sh

# Default command
CMD ["/build/under-docker-build-installer.sh"]
