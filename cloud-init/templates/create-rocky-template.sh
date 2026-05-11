#!/bin/bash
# Rocky Linux 10 Cloud-Init Template for Proxmox
# Usage: bash create-rocky-template.sh

set -e # stop on any error

VMID=9001
STORAGE="local-lvm"
BRIDGE="lab"
CI_USER="javice"
TEMPLATE_NAME="rocky10-template"
IMAGE_NAME="Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"
IMAGE_URL="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/${IMAGE_NAME}"
IMAGE_DIR="/var/lib/vz/template/iso"
IMAGE_PATH="${IMAGE_DIR}/${IMAGE_NAME}"

echo "Checking for cloud image..."
if [ -f "${IMAGE_PATH}" ]; then
    echo "Image found at ${IMAGE_PATH} — skipping download."
else
    echo "Image not found — downloading to ${IMAGE_DIR}..."
    wget -O "${IMAGE_PATH}" "${IMAGE_URL}"
    echo "Download complete."
fi

echo "Creating VM shell..."
qm create ${VMID} \
--name ${TEMPLATE_NAME} \
--memory 2048 \
--cores 2 \
--net0 virtio,bridge=${BRIDGE} \
--ostype l26 \
--machine q35 \
--agent enabled=1 \
--cpu host \
--scsihw virtio-scsi-pci

echo "Importing disk..."
qm importdisk ${VMID} "${IMAGE_PATH}" ${STORAGE}

echo "Attaching disk..."
qm set ${VMID} --scsi0 ${STORAGE}:vm-${VMID}-disk-0,discard=on
qm set ${VMID} --boot order=scsi0
qm set ${VMID} --ide2 ${STORAGE}:cloudinit
qm set ${VMID} --serial0 socket --vga serial0

echo "Configuring cloud-init..."
qm set ${VMID} --ciuser ${CI_USER}
qm set ${VMID} --ipconfig0 ip=dhcp
qm set ${VMID} --sshkeys ~/.ssh/id_ed25519.pub

echo "Resizing disk..."
qm resize ${VMID} scsi0 +6G

echo "Converting to template..."
qm template ${VMID}

echo "Done. Template ${VMID} created."
