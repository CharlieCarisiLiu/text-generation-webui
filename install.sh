#!/bin/bash
mkdir /datadisk
chown -R sysadmin:sysadmin /datadisk
# Create the setup-disk.sh script
cat << 'EOF' > /var/lib/cloud/scripts/per-boot/setup-disk.sh
#!/bin/bash
# Ensure the device exists
if [ -b /dev/nvme0n1 ]; then
    # Create a GPT partition table and a single partition
    parted /dev/nvme0n1 --script mklabel gpt
    parted /dev/nvme0n1 --script mkpart primary ext4 0% 100%

    # Format the partition with ext4 filesystem
    mkfs.ext4 /dev/nvme0n1p1

    # Create mount point and mount the disk
    mkdir -p /datadisk
    mount /dev/nvme0n1p1 /datadisk
fi
EOF

# Make the setup-disk.sh script executable
chmod +x /var/lib/cloud/scripts/per-boot/setup-disk.sh

# Create or update the cloud-init configuration file
cat << 'EOF' > /etc/cloud/cloud.cfg.d/99_custom.cfg
# /etc/cloud/cloud.cfg.d/99_custom.cfg
cloud_final_modules:
  - scripts-per-boot
EOF

echo "Disk setup script installed and configured to run at every boot."

cat << 'EOF' > /etc/systemd/system/pinky.service
[Unit]
Description=PINKY
After=default.target

[Service]
ExecStart=/home/sysadmin/text-generation-webui/run.sh

[Install]
WantedBy=default.target
EOF

systemctl enable pinky

apt install gpustat

sudo -u sysadmin LAUNCH_AFTER_INSTALL=N GPU_CHOICE=A USE_CUDA118=N ./start_linux.sh

echo "Done! Rebooting"

reboot now