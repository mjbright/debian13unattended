
SHOW_LOGO() {
    cat <<EOF
[0m[0m[48;2;255;255;255m[38;2;0;0;0m                                   [38;2;255;255;255m[48;2;0;0;0m
[48;5;231m [48;5;21m/[48;5;21m[38;5;20m[1m                               [38;5;231m[48;5;21m\[48;5;21m[48;5;231m [0m[0m [48;5;232m [38;5;232m
[48;5;231m [48;5;21m [48;5;231m[38;5;20m[1m                               [48;5;21m [48;5;231m [0m[0m
[48;5;231m [48;5;21m [48;5;231m[38;5;20m[1m      @mjbright CONSULTING     [48;5;21m [48;5;231m [0m[0m
[48;5;231m [48;5;21m [48;5;231m[38;5;20m[1m                               [48;5;21m [48;5;231m [0m[0m
[48;5;231m [48;5;21m\[48;5;21m[38;5;20m[1m                               [38;5;231m[48;5;21m/[48;5;21m[48;5;231m [0m[0m [48;5;232m [38;5;232m
[48;5;231m                                   [0m[0m [0m[0m
EOF
}

echo "EXECUTING $0"
SHOW_LOGO

set -x
apt-get update
apt-get install -y jq sudo

NEW_USER=admin66

adduser -gecos "User ${NEW_USER}" ${NEW_USER} --disabled-password

mkdir -p /home/${NEW_USER}/.ssh


# From: ~/.ssh/nuc3_ed25519.pub
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSgp20nvALXpqmIwsE5wFnz2OxNklJ63XspuVU9Mi6S mjb@NUC3" >> /home/${NEW_USER}/.ssh/authorized_keys

chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}/

