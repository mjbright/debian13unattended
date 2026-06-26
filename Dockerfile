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
COPY docker-scripts/build-installer.sh /build/build-installer.sh

# Copy late_command script
COPY preseed-late-command.sh /build/preseed-late-command.sh

RUN chmod +x /build/build-installer.sh

# Default command
CMD ["/build/build-installer.sh"]
