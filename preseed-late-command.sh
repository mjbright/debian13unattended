#!/usr/bin/env bash

# All this script runs under in-target - thus on the target environment (but invoked from the installer)

DEBUG=0
DEBUG=1

PUB_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSgp20nvALXpqmIwsE5wFnz2OxNklJ63XspuVU9Mi6S mjb@NUC3'
echo $PUB_KEY > /root/.ssh/authorized_keys

SUBNET=192.168.1
GW=254

LOG=/root/preseed/$( basename $0 ).log

echo "Logging $( basename $0 ) output to $LOG"
exec  > $LOG 2>&1

ADMIN_USER=admin66

# Console access only:
DEBUG_USER=debug66
DEBUG_MDP=debug66

#set -x
echo; echo "-- Mounted volumes:"
mount
df

BOOT_PART=$( df | grep /boot | awk '{ print $1; }' )
for disk in $( fdisk -l | grep "^Disk /dev/" | sed 's/: .*//' ); do [ "$disk" = "Disk" ] && continue; echo $BOOT_PART | grep -q $disk && break; done  ;
BOOT_DISK=$disk
echo "BOOT_PART=$BOOT_PART BOOK_DISK=$BOOT_DISK"

echo; echo "-- Enable ssh:"
systemctl enable ssh

# DISABLED CDROM (causing stalled install under QEMU):
#    echo; echo "-- Adding cdrom source:"
#    # dry-run:
#    sudo apt-cdrom --no-act add 
#    #if everything is OK:
#    # can cd contents:
#    sudo apt-cdrom add 
#    sudo apt-cdrom ident 
#    #sudo apt-cdrom -d "/cdrom" -r
#    #sudo apt-cdrom --cdrom "/cdrom" -r

#touch /root/.here5
echo; echo "-- Installing some packages:"
APT_PACKAGES="sudo rsync jq psutils tree python3-venv python3-pip lm-sensors neofetch"
CMD="apt-get install -y $APT_PACKAGES"
echo "---- $CMD"
$CMD > /root/apt-get.install.log 2>&1
grep "newly installed" /root/apt-get.install.log 2>&1


#touch /root/.here6
echo; echo "-- Running extra scripts:"
for script in /root/additional-scripts/[0-9].*.sh; do
    echo "---- bash -x $script"
    bash -x $script
done >/root/additional-scripts.log 2>&1

echo; echo "-- Copying in extra files:"
ls -al additional-files/etc/update-motd.d/11-motd
chmod +x additional-files/etc/update-motd.d/11-motd
ls -al additional-files/etc/update-motd.d/11-motd

rsync -av /root/additional-files/ /

#touch /root/.here7
echo; echo "-- Looking for late_command in /var/log/installer/cdebconf/questions.dat:"
grep -A20 -i late_command /var/log/installer/cdebconf/questions.dat

echo; echo "-- Gathering machine specific information:"

MAC=$(cat /sys/class/net/$(ls /sys/class/net | grep -v lo | head -1)/address | tr ':' '-'); \
UUID=$(dmidecode -s system-uuid | tr '[:upper:]' '[:lower:]'); \
PRODUCT=$(dmidecode -s system-product-name | tr ' ' '_'); \

{
    echo; echo "-- Machine identifying information:"
    echo "MAC=$MAC"
    echo "UUID=$UUID"
    echo "PRODUCT=$PRODUCT"

    echo; echo "-- CPUs:"
    grep "model name" /proc/cpuinfo
    echo; echo "-- Memory:"
    head -1 /proc/meminfo
    echo; echo "-- Boot Disk Partitions:"
    fdisk -l $BOOT_DISK
} > /root/machine.info

DISABLE_SSH_ROOT_LOGIN() {
   { grep -v PermitRootLogin /etc/ssh/sshd_config; echo "PermitRootLogin no"; } | tee /etc/ssh/sshd_config
}

INSTALL_HYPERVISOR_TOOLS() {
    # Detect hypervisor and install the appropriate guest agent
    VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
    echo "Detected virtualization: $VIRT"
    
    case "$VIRT" in
        kvm|qemu) apt-get install -y qemu-guest-agent ;;
        vmware) apt-get install -y open-vm-tools ;;
        microsoft) apt-get install -y hyperv-daemons ;;
        xen) apt-get install -y xe-guest-utilities ;;
        oracle) apt-get install -y virtualbox-guest-utils ;;
        *)
            echo "No hypervisor-specific guest agent required (bare metal or unsupported hypervisor)"
            ;;
    esac
}

FINAL_COMMON() {
    adduser -gecos 'User ${ADMIN_USER}' ${ADMIN_USER} --disabled-password 2>&1

    # Assigning a long random password, so that account is unlocked for ssh/key-based access:
    echo "admin66:$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 48)" | sudo chpasswd
    # Automatically unlocks the account - no need for sudo usermod -U admin66, or for sudo passwd -u admin66

    mkdir -p /home/${ADMIN_USER}/.ssh
    echo $PUB_KEY >> /home/${ADMIN_USER}/.ssh/authorized_keys
    chown -R ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}/
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/${ADMIN_USER}

    [ $DEBUG -ne 0 ] && {
        # Console access only
        echo "$DEBUG_USER:$DEBUG_MDP" |sudo chpasswd
    }

    # TODO:
    # - disable (ssh) root   login
    # - disable (ssh) debian login (no passwd entry: safe?)
    #   testing with ssh login for now ...
    
    DEBIAN_USER=debian
    mkdir -p /home/${DEBIAN_USER}/.ssh
    echo $PUB_KEY >> /home/${DEBIAN_USER}/.ssh/authorized_keys
    chown -R ${DEBIAN_USER}:${DEBIAN_USER} /home/${DEBIAN_USER}/

    DISABLE_SSH_ROOT_LOGIN
    # Disable 'debian' ssh login:
    mv /home/${DEBIAN_USER}/.ssh /home/${DEBIAN_USER}/.ssh.disabled


    echo "Careful: can cause issues where packages are updated:"
    { echo; cat /root/machine.info;
      echo; ip a;
      echo; echo "$(hostname): $(hostname -I)"; echo;
    } | tee -a /etc/issue | tee -a /etc/issue.net

    { echo; cat /root/machine.info;
      echo; echo "$(hostname): $(hostname -I)"; echo;
    } |tee -a /dev/console
}

CONFIGURE_LENOVO_CARBON() {
    HOST=carbonx1

    echo "[$HOST] Machine identified as '2018 Lenovo Carbon'"
    # FAILS: hostnamectl set-hostname $HOST
    echo $HOST > /etc/hostname
}

CONFIGURE_HOST() {
    HOST=$1; shift
    DEV=$1; shift
    IP=$1; shift
    DESC="$1"; shift
    [ -z "$DESC" ] && DESC="$HOST"

    echo "[$HOST] Machine identified as $DESC"
    # FAILS: hostnamectl set-hostname $HOST
    echo $HOST > /etc/hostname

    CONFIGURE_STATIC_NETWORKING $IP enp1s0
}

OLD_CONFIGURE_NUC5_BEELINK() {
    HOST=nuc5-beelink

    echo "[$HOST] Machine identified as NUC5-Beelink [N100]"
    # FAILS: hostnamectl set-hostname $HOST
    echo $HOST > /etc/hostname

    IP=192.168.1.235
    CONFIGURE_STATIC_NETWORKING $IP enp1s0
}

CONFIGURE_PROX3() {
    HOST=prox3

    echo "[$HOST] Machine identified as $HOST [machine type??]"
    # FAILS: hostnamectl set-hostname $HOST
    echo $HOST > /etc/hostname
}

CONFIGURE_PROX5() {
    HOST=prox5

    echo "[$HOST] Machine identified as $HOST [machine type??]"
    # FAILS: hostnamectl set-hostname $HOST
    echo $HOST > /etc/hostname
}

CONFIGURE_STATIC_NETWORKING() {
    IP=$1; shift
    DEVICE=$1; shift

    [ ! -f /etc/network/interfaces.bak ] &&
        cp -a /etc/network/interfaces /etc/network/interfaces.bak

    sed \
	-e "s/__IP__/$IP/g" \
	-e "s/__DEVICE__/$DEVICE/g" \
	-e "s/__SUBNET__/$SUBNET/g" \
	-e "s/__GW__/$GW/g" \
        additional-files/root/etc-network-interfaces.template > /etc/network/interfaces

    grep -q " $HOST$" /etc/hosts || {
        echo "# $DESC"
        echo $IP $HOST
    } | tee -a /etc/hosts

    systemctl restart networking
}

die() {
    echo "die: $*" >&2
    exit 1
}

case $MAC in

  # QEMU_MAC=52:54:00:12:34:56
  52-54-00-12-34-56)
    CONFIGURE_HOST "qemu-tester" eno1 192.168.1.199 "QEMU Tester"
    ;;

  8c-16-45-5f-af-e1)
    # CONFIGURE_LENOVO_CARBON;;
    CONFIGURE_HOST "lenovo-carbon" enp1s0 192.168.1.236 "Lenovo Carbon X1 [2018]"
    ;;

  7c-83-34-bb-bc-90)
    CONFIGURE_HOST "nuc5-beelink" enp1s0 192.168.1.235 "NUC5-Beelink [N100]"
    ;;
    # CONFIGURE_NUC5_BEELINK;;
    #MAC='7c-83-34-bb-bc-90' UUID='03000200-0400-0500-0006-000700080009' PRODUCT='MINI_S'

  8c-70-60-4c-3f-bd)
    # CONFIGURE_PROX3;;
    CONFIGURE_HOST "prox3" enp1s0 192.168.1.243 "Proxmox 3 (metal fins?)"
    ;;
  38-f3-ab-f7-66-b5)
    CONFIGURE_HOST "prox5" enp1s0 192.168.1.245 "Proxmox 5 (Lenovo Tiny)"
    ;;

  1c-69-7a-a0-b7-20)
    CONFIGURE_HOST "prox7" enp1s0 192.168.1.247 "Proxmox 7 ??"
    ;;
    # CONFIGURE_PROX7;;
    # ?? xx-xx-xx-xx-xx-xx) CONFIGURE_PROX5;;

    *) echo "Unrecognized machine - MAC='$MAC' UUID='$UUID' PRODUCT='$PRODUCT'";;
    #*) die "Unrecognized machine - MAC='$MAC' UUID='$UUID' PRODUCT='$PRODUCT'";;
esac

INSTALL_HYPERVISOR_TOOLS
FINAL_COMMON

exit 0

