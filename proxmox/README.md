# proxmox

Host: `cloud` (i7-13700K, Proxmox VE 9, Intel UHD 770 iGPU split via SR-IOV into
VFs passed through to VMs 100/110/112).

- `i915-sriov-update.sh` - deployed to `/usr/local/sbin` on the host. Run after
  `apt update && apt full-upgrade` to pick up new i915-sriov-dkms releases and make
  sure the module is built for the running kernel. Kernel-version rebuilds for an
  already-installed i915-sriov-dkms version happen automatically via dkms's kernel
  postinst hook, as long as `proxmox-default-headers` is installed (it is).
