# Profile and Laptop Configurations

## Machines

| Host id | Machine | Shell | Notes |
|---------|---------|-------|-------|
| `work-mac` | MBP M4 (Work) | zsh | Enterprise Java (Maven, Kubernetes, Mirrord); loads `work/` |
| `personal-mac` | MBP M2 (Personal) | zsh | Gaming and hobby programming (Gradle, Podman) |
| `ubuntu-vdi` | Ubuntu VDI (personal, RDP) | bash | Provisioned by `setup/ubuntu/setup.sh` |
| `win-vdi` | VDI (Windows 11, remote) | bash | MinGW64 / Git Bash |

The Dell Lenovo (Windows) physical laptop has no config here.

## Install / update

```bash
git pull
./install.sh <host-id>
```

`install.sh` writes small stubs for `~/.zshrc` or `~/.bashrc` and for `~/.gitconfig`. Each stub points into this repo. It also symlinks `~/.tmux.conf` and `~/.config/herdr/config.toml`. Anything it replaces is kept as `<file>.pre-profile.<timestamp>`. Keys in an old `~/.gitconfig` that the repo doesn't define, such as credential helpers, are carried into the stub. The script is safe to re-run.

The repo is the only copy, so edit files here, then run `reload` (`refreshZsh` still works). Run `dotfiles pull` or `dotfiles push` to sync with origin.

## Structure

| Path | Contents |
|------|----------|
| `install.sh` | Per-machine deploy: rc and gitconfig stubs, tmux and herdr symlinks |
| `shell/zsh/` | zsh entry point (`init.zsh`), prompt, iTerm2 badge, herdr Agents panel hook, `secrets` integration |
| `shell/bash/` | bash entry point (`init.bash`), colors, prompt |
| `shell/common/` | Shared by zsh and bash: env and PATH, ssh-agent, git helpers, JDK switching, `reload`/`dotfiles` |
| `shell/hosts/` | The only per-machine shell layer, one file per host id, loaded last |
| `work/` | Upgrade-only shell setup (kubectl, ECR, Podman, Maven, Claude aliases) and scripts in `work/bin/` |
| `config/git/` | Per-host `includeIf` routing (`hosts/`) and per-directory identities (`identities/`) |
| `config/tmux/` | tmux config (MBP M4) that hosts Claude Code sessions for FleetView |
| `config/herdr/` | herdr config |
| `bin/` | On `PATH` everywhere: `screenshot-target.sh` |
| `setup/macos/` | Brewfiles per Mac, brew leaves, Homebrew tips |
| `setup/ubuntu/` | Idempotent setup script for the Ubuntu dev box, plus the files it deploys |
| `setup/docker/` | Idempotent docker context and podman connection setup for remote hosts |
| `setup/proxmox/` | i915 SR-IOV notes and update script for the `cloud` host |
| `docs/` | NAS mount instructions (vault.stapledon.ca) |
| `assets/profile_pics/` | Profile photos and cartoon variants |

## Load order

zsh: `~/.zshrc` stub → `shell/zsh/init.zsh` → `shell/common/*.sh` → `shell/zsh/*.zsh` → `~/.zshrc.secrets` → `shell/hosts/<host>.zsh`.

bash follows the same order, minus the secrets file. The host file loads last, so it wins.
