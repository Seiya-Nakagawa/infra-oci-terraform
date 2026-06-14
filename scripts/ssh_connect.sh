#!/bin/bash

# OCI SSH Connect Script v1.0
# This script connects directly to the Compute instance using its public IP address.

set -e

# --- Default Values ---
SSH_PRIV_KEY_FILE="$HOME/.ssh/id_rsa"

# --- Help Message ---
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i <key_path>  SSH private key path (default: $HOME/.ssh/id_rsa)"
    echo "  -h             Show this help message"
}

# --- Parse Arguments ---
while getopts "i:h" opt; do
    case "$opt" in
        i) SSH_PRIV_KEY_FILE=$OPTARG ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done

echo "=== OCI SSH Connect Script v1.0 ==="

# --- Check Requirements ---
if [ ! -f "$SSH_PRIV_KEY_FILE" ]; then
    echo "Error: SSH private key file not found: $SSH_PRIV_KEY_FILE"
    exit 1
fi

# --- Get Info from Terraform ---
echo "[1/2] Terraformから情報を取得中..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"

if [ ! -d "$TF_DIR" ]; then
    echo "Error: Terraformディレクトリが見つかりません: $TF_DIR"
    exit 1
fi

TF_OUTPUT=$(cd "$TF_DIR" && terraform output -json)

INSTANCE_IP=$(echo "$TF_OUTPUT" | jq -r '.instance_public_ip.value // empty')
OS_USERNAME=$(echo "$TF_OUTPUT" | jq -r '.instance_user.value // "seiya"')

if [ -z "$INSTANCE_IP" ]; then
    echo "Error: terraform output からパブリックIPアドレス (instance_public_ip) が取得できませんでした。"
    exit 1
fi

echo "  Instance IP: $INSTANCE_IP"
echo "  User: $OS_USERNAME"
echo "  Key: $SSH_PRIV_KEY_FILE"

# --- Execute SSH ---
echo "[2/2] SSH接続を開始します..."
echo "ssh -i $SSH_PRIV_KEY_FILE ${OS_USERNAME}@${INSTANCE_IP}"
ssh -i "$SSH_PRIV_KEY_FILE" "${OS_USERNAME}@${INSTANCE_IP}"
