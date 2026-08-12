# proxmox

Host: `cloud` (i7-13700K, Proxmox VE 9, Intel UHD 770 iGPU split via SR-IOV into
3 VFs passed through to VMs 100/110/112). Secure Boot is disabled on the host
(BIOS) so the DKMS-built i915-sriov module doesn't need MOK enrollment.

- `i915-sriov-update.sh` - deployed to `/usr/local/sbin` on the host. Run after
  `apt update && apt full-upgrade` to pick up new i915-sriov-dkms releases and make
  sure the module is built for the running kernel. Kernel-version rebuilds for an
  already-installed i915-sriov-dkms version happen automatically via dkms's kernel
  postinst hook, as long as `proxmox-default-headers` is installed (it is).

## VF assignment

| VM  | Name              | PCI VF       | Notes |
|-----|-------------------|--------------|-------|
| 100 | VDI-w11-Devel     | 0000:00:02.1 | Windows guest, i440fx |
| 110 | VDI-Ubuntu-26.04  | 0000:00:02.2 | q35, hugepages/pinning not configured |
| 112 | Portainer         | 0000:00:02.3 | q35 (migrated from i440fx), upgraded 24.04->26.04 LTS for kernel compat, see below |

All three VMs are fully working: VF assigned, guest driver installed, `Status: OK`
in Device Manager / driver bound in `lspci -k`.

Host cmdline: `intel_iommu=on iommu=pt i915.enable_guc=3 i915.max_vfs=3
module_blacklist=xe` (`/etc/default/grub`). VF count is set at boot via
`sysfsutils`/`/etc/sysfs.conf` (`sriov_numvfs = 3` on `0000:00:02.0`), not an
ad-hoc systemd unit.

## VM config pattern (per passthrough VM)

- `hostpci0: <VF>,x-vga=1` (add `pcie=1` only on `machine: q35`; i440fx doesn't
  support the pcie flag on hostpci and qm start will fail with a "q35 machine
  model is not enabled" error if you include it there)
- `vga: none` - the VF is the sole display. This blanks the Proxmox
  noVNC/SPICE console once the guest's GPU driver takes over.
- `serial0: socket` - emulated serial console, independent of the GPU, viewable
  via `qm terminal <vmid>` or the web UI's console dropdown ("xterm.js"). Add
  `console=ttyS0,115200n8` to the guest's kernel cmdline (GRUB
  `GRUB_CMDLINE_LINUX_DEFAULT`, then `update-grub`) so a getty actually comes up
  on it - this is how you get a console back after `vga: none` removes the
  normal one.
- **Do not run vga (virtio/virtio-gl) and a headless passthrough VF at the same
  time.** Two GPUs where the second has no display output confuses Wayland
  compositors (GNOME/Mutter) - symptoms were apps losing their Wayland
  connection on launch (including the terminal) and the whole session
  eventually crashing to a text tty. Pick one display path per VM.
- Non-hotpluggable changes (`hostpci`, `vga`, `serial0`) land in the *pending*
  config on a running VM (`qm set` is safe to run live) but only take effect
  on a full `qm stop && qm start` - a guest-initiated reboot or `qm reboot`
  keeps the old QEMU process and hardware list.

## Guest-side driver (Linux)

The passed-through VF needs the **same** `strongtz/i915-sriov-dkms` driver
installed inside the guest - the distro's stock `i915`/`xe` modules don't
support running as an SR-IOV VF and fail to probe it (`Device is
non-operational; MMIO access returns 0xFFFFFFFF`). Install the matching
release the same way as the host: download the `.deb` for
`strongtz/i915-sriov-dkms`, `dpkg -i`, ensure `linux-headers-$(uname -r)` is
present.

**Kernel version matters.** The dkms package pins a `BUILD_EXCLUSIVE_KERNEL`
regex (e.g. `^(7\.[0-1]|6\.1[7-9])` for the 2026.08.08 release) and silently
skips building for anything outside it. VM 112 was on Ubuntu 24.04.4
(`6.8.0-137-generic`) and the build kept getting skipped with no obvious
error unless you read the dkms output closely - it doesn't fail loudly, it
just doesn't produce a module for your kernel. Fixed by upgrading the guest
to 26.04 LTS (`7.0.x` kernel, in range) via repeated `do-release-upgrade`
hops (`Prompt=normal` in `/etc/update-manager/release-upgrades` to get
offered interim releases; direct LTS->LTS jump isn't offered until the
target LTS's `.1` point release ships). Take a `qm snapshot` first.

**Secure Boot enforcement is inconsistent, don't rely on "it'll just taint."**
The DKMS build self-signs with an unenrolled MOK key. On VM 110 an
unenrolled key only tainted the kernel and the module still loaded; on VM
112 (same distro/kernel, Ubuntu 26.04 / `7.0.0-29-generic`) it was a hard
`modprobe: Key was rejected by service` / `Loading of module with
unavailable key is rejected`. Don't assume one guest's behavior predicts
another's - check `mokutil --sb-state` and just disable Secure Boot in the
guest's OVMF firmware (Esc at boot -> Device Manager -> Secure Boot
Configuration) up front. Same reasoning as the host: homelab, skip the MOK
enrollment dance.

**Switching a guest's `machine` type from i440fx to q35 renames its NICs.**
Ubuntu's predictable-interface-naming derives the name from PCI topology;
i440fx has no PCIe bridge so NICs get `ensN`, q35 puts them behind a root
port so they become `enpXsY`. If netplan/cloud-init pins the old name (it
does by default), the interface comes up with no config after the switch.
Fix: pin the name back with a MAC-matched systemd `.link` file
(`/etc/systemd/network/10-ensN.link`, `[Match] MACAddress=...` / `[Link]
Name=ensN`) rather than editing the generated netplan (cloud-init
regenerates it and will just clobber a hand edit).

## Guest-side driver (Windows, VM 100)

Windows doesn't use `strongtz/i915-sriov-dkms` at all - that project is a
Linux DKMS module. The VF reports the real Intel hardware ID
(`8086:a780`), so the standard Intel Graphics driver (DCH, from
intel.com) recognizes and binds it directly - no special package.
Confirmed working: Device Manager shows "Intel(R) UHD Graphics 770"
(`PCI\VEN_8086&DEV_A780...`) with `Status: OK`. VM 100 also has no
`qemu-guest-agent` installed by default, unlike the Linux guests, so
`qm guest exec`/`qm agent` won't work there until it's installed manually.
