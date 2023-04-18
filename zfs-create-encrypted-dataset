#!/bin/bash

# Prompt user for dataset name
read -p "Enter dataset name: " dataset_name

dataset_name2=${dataset_name//\//-}

dataset_key=/root/$dataset_name2.key

# Create password file and set permissions
head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32 > $dataset_key
chmod 400 $dataset_key

# Create encrypted dataset in Proxmox using the password file as the key
zfs create -o encryption=aes-256-gcm -o keyformat=raw -o keylocation=file://$dataset_key $dataset_name

zfs get encryption,encryptionroot,keylocation,keyformat,keystatus | grep $dataset_name

# Create service to automatically activate encrypted dataset, if service exists, skip step (in case of creating multiple encrypted datasets)
if [ ! -e /etc/systemd/system/zfs-load-key@.service ]; then

cat << 'EOF' > /etc/systemd/system/zfs-load-key@.service
[Unit]
Description=Load ZFS keys
DefaultDependencies=no
Before=zfs-mount.service
After=zfs-import.target
Requires=zfs-import.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/zfs load-key %I

[Install]
WantedBy=zfs-mount.service
EOF

fi

# Enable and start the service
systemctl enable zfs-load-key@$dataset_name2

# Print password file path to console
echo "Encryption password for dataset $dataset_name stored in $dataset_key"
echo "Make sure to store this password file in a safe location!"
