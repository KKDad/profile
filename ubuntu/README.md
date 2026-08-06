# Ubuntu dev box setup

`setup.sh` is an idempotent setup script for the Ubuntu dev box (currently the
personal, RDP-accessible VDI). Safe to re-run — every step checks current
state before making changes.

```
bash ubuntu/setup.sh
```

## What it does

1. **Base packages** — installs `git`, `curl`, `build-essential`, and `gh`
   (GitHub CLI, via its own apt source) if missing.
2. **Google Chrome** — installs the `.deb` if `google-chrome` isn't already
   on the `PATH`.
3. **Mac-style window layout** — moves window buttons to the top-left via
   `gsettings`, plus Zorin-dash tweaks if that extension schema is present.
4. **Native GNOME RDP** — generates an RSA 4096 self-signed TLS cert for
   `gnome-remote-desktop` only if one isn't already present and valid,
   configures `grdctl`, prompts for credentials only if none are set (or you
   opt to overwrite), and enables the `gnome-remote-desktop` user service.
   This box uses GNOME's native RDP server, not xrdp.
5. **GNOME-macOS-Tahoe theming** — clones (or pulls)
   [kayozxo/GNOME-macOS-Tahoe](https://github.com/kayozxo/GNOME-macOS-Tahoe)
   into `~/git` and runs its installer non-interactively with `-d -la -w`
   (dark theme, libadwaita override, Tahoe wallpapers installed to
   `/usr/share/backgrounds/Tahoe/`). No `--flatpak` — this box uses Snap, not
   Flatpak, and that flag also has an upstream quirk where it `exit`s the
   installer immediately, before any of the other flags get applied. It's a
   third-party tool — see that repo's own README for uninstalling, accent
   colors, and extra manual steps (recommended shell extensions, etc.).
6. **GNOME extensions** — installs `gnome-shell-ubuntu-extensions` (Desktop
   Icons NG, Ubuntu Dock, Tiling Assistant) and `gnome-shell-extension-user-theme`
   via apt (replacing any manual extensions.gnome.org install, which doesn't
   register its `gsettings` schema system-wide), then enables all four.
7. **Appearance settings** — applies the dark Tahoe GTK/shell theme, Yaru-dark
   icons, the tweaked dock (bottom position, 48px icons, 80% opacity) and dock
   favorites, and sets the Tahoe dark wallpaper installed in step 5 as both
   the desktop background and screensaver image.
8. **Dev language tooling** — installs OpenJDK 17/21/25 via apt (for the
   `java17`/`java21`/`java25` switcher functions in `ubuntu-dot.bashrc`; the
   apt/`update-alternatives` default JDK is left untouched), installs
   [nvm](https://github.com/nvm-sh/nvm) if missing, and installs
   [pyenv](https://github.com/pyenv/pyenv) plus its Debian/Ubuntu build
   dependencies if missing.
9. **Dotfiles** — deploys `env/bash/ubuntu-dot.bashrc` to `~/.bashrc` if the
   repo copy is newer. After that, use the `update` and `refreshBash`
   shell functions (defined in that file) to keep the two in sync.
