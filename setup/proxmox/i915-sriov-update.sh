#!/bin/bash
# Keep i915-sriov-dkms (https://github.com/strongtz/i915-sriov-dkms) current on a
# Proxmox host with an Intel iGPU split into SR-IOV VFs.
#
# Run this any time after `apt update && apt full-upgrade` (including kernel bumps).
# Kernel-triggered rebuilds for a version already installed happen automatically via
# dkms's own kernel postinst hook + proxmox-default-headers; this script's job is
# picking up new *upstream releases* of i915-sriov-dkms, which apt doesn't track
# since the package isn't installed from a repo.
#
# Safe to re-run; no-ops if already on the latest release and already built for the
# running kernel.
set -euo pipefail

REPO="strongtz/i915-sriov-dkms"
PF="0000:00:02.0"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

if [[ $EUID -ne 0 ]]; then
    echo "must run as root" >&2
    exit 1
fi

latest_tag=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
if [[ -z "$latest_tag" ]]; then
    echo "could not determine latest release tag from GitHub API" >&2
    exit 1
fi

installed_ver=$(dpkg-query -W -f='${Version}' i915-sriov-dkms 2>/dev/null || true)

echo "installed: ${installed_ver:-<none>}   latest: ${latest_tag}"

if [[ "$installed_ver" != "$latest_tag" ]]; then
    echo "==> installing i915-sriov-dkms ${latest_tag}"
    deb="i915-sriov-dkms_${latest_tag}_amd64.deb"
    curl -fsSL -o "${WORKDIR}/${deb}" \
        "https://github.com/${REPO}/releases/download/${latest_tag}/${deb}"
    dpkg -i "${WORKDIR}/${deb}"
else
    echo "==> already on latest release"
fi

running_kernel="$(uname -r)"
if ! dkms status -k "$running_kernel" 2>/dev/null | grep -q "installed"; then
    echo "==> module not yet built for running kernel ${running_kernel}"
    if ! dpkg -l "proxmox-headers-${running_kernel}" &>/dev/null; then
        echo "    installing matching headers"
        apt-get install -y "proxmox-headers-${running_kernel}"
    fi
    dkms autoinstall -k "$running_kernel"
fi

echo
echo "=== dkms status ==="
dkms status
echo
echo "=== current VF count on ${PF} (0 until next boot after a fresh install) ==="
cat "/sys/bus/pci/devices/${PF}/sriov_numvfs" 2>/dev/null || echo "sysfs attribute not present - module not loaded on this PF yet"
