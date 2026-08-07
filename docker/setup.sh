#!/usr/bin/env bash
# Idempotent setup for docker/podman remote connections. Safe to re-run.
set -e

REMOTE_NAME="portainer"
REMOTE_HOST="portainer.stapledon.ca"
REMOTE_USER="root"

check_remote_ssh_access() {
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" true 2>/dev/null; then
        echo "    [-] SSH key access to ${REMOTE_USER}@${REMOTE_HOST} already works."
        return 0
    fi

    echo "    [!] Cannot SSH into ${REMOTE_USER}@${REMOTE_HOST} with key auth."

    local key
    for key in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub" "$HOME/.ssh/id_ecdsa.pub"; do
        if [ -f "$key" ]; then
            echo "    [!] Local key found ($key) but not authorized on the remote host. Copy it over:"
            echo "        ssh-copy-id -i \"$key\" ${REMOTE_USER}@${REMOTE_HOST}"
            return 1
        fi
    done

    echo "    [!] No local SSH key found (~/.ssh/id_ed25519, id_rsa, id_ecdsa)."
    echo "        Generate one, then copy it over:"
    echo "        ssh-keygen -t ed25519 && ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"
    return 1
}

echo "--> Checking SSH key access to ${REMOTE_USER}@${REMOTE_HOST}..."
if ! check_remote_ssh_access; then
    echo "    [!] Continuing to register the context/connection anyway, but it won't work until the key is copied over."
fi

if command -v docker &> /dev/null && docker context ls &> /dev/null; then
    echo "--> Configuring docker contexts..."

    if docker context ls --format '{{.Name}}' | grep -qx "$REMOTE_NAME"; then
        echo "    [-] docker context '$REMOTE_NAME' already exists."
    else
        docker context create "$REMOTE_NAME" --docker "host=ssh://root@${REMOTE_HOST}"
        echo "    [✓] Created docker context '$REMOTE_NAME' (ssh://root@${REMOTE_HOST})."
    fi

    if command -v podman &> /dev/null; then
        PODMAN_SOCKET="$(podman info --format '{{.Host.RemoteSocket.Path}}' 2>/dev/null || true)"
        if [ -n "$PODMAN_SOCKET" ]; then
            if docker context ls --format '{{.Name}}' | grep -qx podman; then
                echo "    [-] docker context 'podman' already exists."
            else
                docker context create podman --docker "host=unix://${PODMAN_SOCKET}"
                echo "    [✓] Created docker context 'podman' (unix://${PODMAN_SOCKET})."
            fi
        fi
    fi

    echo "    Switch with: docker context use podman | docker context use ${REMOTE_NAME}"

elif command -v podman &> /dev/null; then
    echo "--> Configuring podman remote connections..."

    if podman system connection ls --format '{{.Name}}' | grep -qx "$REMOTE_NAME"; then
        echo "    [-] podman connection '$REMOTE_NAME' already exists."
    else
        podman system connection add "$REMOTE_NAME" "ssh://root@${REMOTE_HOST}/run/podman/podman.sock"
        echo "    [✓] Created podman connection '$REMOTE_NAME' (ssh://root@${REMOTE_HOST})."
    fi

    echo "    Use with: podman --connection ${REMOTE_NAME} <cmd> | podman system connection default ${REMOTE_NAME}"

else
    echo "--> Neither docker nor podman found on this machine, skipping remote setup."
fi
