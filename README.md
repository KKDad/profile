# Profile and Laptop Configurations

## Machines

- **MBP M4 (Work)** — `env/zsh/dot.zshrc`, `git/dot.gitconfig.work`
  - Enterprise Java development (Maven, Kubernetes, Mirrord)
- **MBP M2 (Personal)** — `env/zsh/laptop-dot.zshrc`, `git/dot.gitconfig.laptop`
  - Gaming and hobby programming (Gradle, Podman, no Kubernetes/Maven)
- **Dell Lenovo (Windows)** — physical laptop
- **VDI (Windows 11, remote)** — `env/ming64/vdi-w11-dot.bashrc`

## Structure

| Path | Contents |
|------|----------|
| `env/zsh/` | Zsh configs, prompt, nvm setup |
| `env/bash/` | Bash configs and prompt |
| `env/ming64/` | VDI shell config (MinGW64/Git Bash) |
| `git/` | Gitconfig per machine, clone/update scripts |
| `homebrew/` | `Brewfile` (MBP M4 work), `Brewfile.laptop` (MBP M2 personal), tips |
| `mounts/` | NAS mount instructions (vault.stapledon.ca) |
| `profile_pics/` | Profile photos and cartoon variants |
