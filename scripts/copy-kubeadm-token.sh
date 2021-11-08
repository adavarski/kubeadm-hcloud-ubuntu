#!/bin/sh
set -eu

mkdir -p "${TARGET}"

echo "${SSH_PRIVATE_KEY}" > "${TARGET}/.ssh_id_private"
chmod 600 "${TARGET}/.ssh_id_private"

# copy kubeadm join data
scp -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "${TARGET}/.ssh_id_private" \
    "${SSH_USERNAME}@${SSH_HOST}:/tmp/kubeadm_*" \
    "${TARGET}/"

scp -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "${TARGET}/.ssh_id_private" \
    "${SSH_USERNAME}@${SSH_HOST}:/etc/kubernetes/admin.conf" \
    "${TARGET}/admin.conf"

# set public ip in admin.conf
sed -i "s/server: .*/server: https:\/\/${SSH_HOST}:6443/g" "${TARGET}/admin.conf"
