#!/usr/bin/bash
set -eu

# Initialize Cluster
if [[ -n "$FEATURE_GATES" ]]
then
  kubeadm init \
    --feature-gates "$FEATURE_GATES" \
    --config /etc/kubeadm-init-config.yml
else
  kubeadm init \
    --config /etc/kubeadm-init-config.yml
fi

# upload certs to be used by other nodes
kubeadm init phase upload-certs --upload-certs --config /etc/kubeadm-init-config.yml | \
  tail -1 > /tmp/kubeadm_upload_certs_key

# create token to join nodes to the cluster
kubeadm token create --config /etc/kubeadm-init-config.yml > /tmp/kubeadm_token

# get CA cert hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* /sha256:/' \
  > /tmp/kubeadm_cacert_hash

# copy config to be used by kubectl on master
mkdir -p "$HOME/.kube"
cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
