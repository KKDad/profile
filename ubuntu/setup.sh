#!/usr/bin/env bash
# Idempotent setup for the Ubuntu dev box. Safe to re-run.
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_DIR="$HOME/git"

echo "===================================================="
echo " Ubuntu dev box setup"
echo "===================================================="

# ---------------------------------------------------------------------
# 1. BASE PACKAGES
# ---------------------------------------------------------------------
echo "--> Verifying base packages..."

NEED_APT_UPDATE=0
declare -a TO_INSTALL=()

command -v git &> /dev/null || TO_INSTALL+=(git)
command -v curl &> /dev/null || TO_INSTALL+=(curl)
dpkg -s build-essential &> /dev/null || TO_INSTALL+=(build-essential)

if [ "${#TO_INSTALL[@]}" -gt 0 ]; then
    sudo apt update -y
    sudo apt install -y "${TO_INSTALL[@]}"
else
    echo "    [-] git, curl, build-essential already installed."
fi

# GitHub CLI (gh) — separate apt source
if ! command -v gh &> /dev/null; then
    echo "    [+] Installing GitHub CLI (gh)..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -y
    sudo apt install -y gh
else
    echo "    [-] GitHub CLI (gh) is already installed."
fi

# ---------------------------------------------------------------------
# 2. GOOGLE CHROME
# ---------------------------------------------------------------------
echo "--> Verifying Google Chrome..."
if ! command -v google-chrome &> /dev/null; then
    echo "    [+] Installing Google Chrome..."
    CHROME_DEB="$(mktemp -t google-chrome-XXXX.deb)"
    wget -q -O "$CHROME_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y "$CHROME_DEB"
    rm -f "$CHROME_DEB"
else
    echo "    [-] Google Chrome is already installed."
fi

# ---------------------------------------------------------------------
# 3. MAC-STYLE WINDOW LAYOUT
# ---------------------------------------------------------------------
echo "--> Configuring macOS-style window layout..."

CURRENT_LAYOUT=$(gsettings get org.gnome.desktop.wm.preferences button-layout)
if [ "$CURRENT_LAYOUT" != "'close,minimize,maximize:'" ]; then
    gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:"
    echo "    [✓] Moved window controls to top-left."
else
    echo "    [-] Window controls already in top-left."
fi

if gsettings list-schemas | grep -q "org.gnome.shell.extensions.zorin-dash"; then
    [ "$(gsettings get org.gnome.shell.extensions.zorin-dash taskbar-alignment)" != "'center'" ] && \
        gsettings set org.gnome.shell.extensions.zorin-dash taskbar-alignment 'center'
    [ "$(gsettings get org.gnome.shell.extensions.zorin-dash intellihide)" != "true" ] && \
        gsettings set org.gnome.shell.extensions.zorin-dash intellihide true
    [ "$(gsettings get org.gnome.shell.extensions.zorin-dash icon-size)" != "40" ] && \
        gsettings set org.gnome.shell.extensions.zorin-dash icon-size 40
    echo "    [✓] Zorin taskbar tailored to Mac dock behavior."
fi

# ---------------------------------------------------------------------
# 4. NATIVE GNOME RDP
# ---------------------------------------------------------------------
echo "--> Configuring GNOME native RDP server..."

if gsettings list-schemas | grep -q "org.gnome.desktop.remote-desktop.rdp"; then
    gsettings set org.gnome.desktop.remote-desktop.rdp screen-share-mode 'mirror-primary'
fi

RDP_DIR="$HOME/.local/share/gnome-remote-desktop"
RDP_CRT="$RDP_DIR/rdp.crt"
RDP_KEY="$RDP_DIR/rdp.key"
mkdir -p "$RDP_DIR"

if [ -f "$RDP_CRT" ] && [ -f "$RDP_KEY" ] && openssl x509 -in "$RDP_CRT" -noout -checkend 0 &> /dev/null; then
    echo "    [-] Valid RDP TLS certificate already present."
else
    echo "    [+] Generating fresh RSA 4096 TLS certificate for GNOME RDP..."
    openssl req -new -newkey rsa:4096 -x509 -days 365 -nodes \
        -out "$RDP_CRT" \
        -keyout "$RDP_KEY" \
        -subj "/CN=$(hostname)"
fi

grdctl rdp set-tls-cert "$RDP_CRT"
grdctl rdp set-tls-key "$RDP_KEY"
grdctl rdp enable
grdctl rdp disable-view-only

RDP_CREDENTIALS="$RDP_DIR/credentials.ini"
if [ -s "$RDP_CREDENTIALS" ]; then
    echo "    [-] RDP credentials are already configured on this system."
    read -p "    [?] Do you want to overwrite the existing RDP credentials? (y/N): " OVERWRITE_CREDS
    OVERWRITE_CREDS=${OVERWRITE_CREDS:-n}
else
    OVERWRITE_CREDS="y"
fi

if [ "$OVERWRITE_CREDS" = "y" ] || [ "$OVERWRITE_CREDS" = "Y" ]; then
    read -p "    Enter RDP Username: " RDP_USER

    printf "    Enter RDP Password: "
    stty -echo
    read RDP_PASS
    stty echo
    echo ""

    if [ -z "$RDP_USER" ] || [ -z "$RDP_PASS" ]; then
        echo "    [!] Error: Username and Password cannot be blank. Skipping credential assignment."
    else
        grdctl rdp set-credentials "$RDP_USER" "$RDP_PASS"
        echo "    [✓] GNOME RDP credentials successfully configured."
    fi
fi

systemctl --user enable --now gnome-remote-desktop
echo "    [✓] GNOME Remote Desktop service enabled and running."

# ---------------------------------------------------------------------
# 5. GNOME-macOS-Tahoe THEMING
# ---------------------------------------------------------------------
echo "--> Applying GNOME-macOS-Tahoe theme..."

mkdir -p "$GIT_DIR"
THEME_DIR="$GIT_DIR/GNOME-macOS-Tahoe"
if [ -d "$THEME_DIR/.git" ]; then
    git -C "$THEME_DIR" pull
else
    git clone https://github.com/kayozxo/GNOME-macOS-Tahoe "$THEME_DIR"
fi

(cd "$THEME_DIR" && bash install.sh -d -w)

# ---------------------------------------------------------------------
# 6. GNOME EXTENSIONS
# ---------------------------------------------------------------------
echo "--> Verifying GNOME Shell extensions..."

declare -a EXT_PKGS_TO_INSTALL=()
dpkg -s gnome-shell-ubuntu-extensions &> /dev/null || EXT_PKGS_TO_INSTALL+=(gnome-shell-ubuntu-extensions)
dpkg -s gnome-shell-extension-user-theme &> /dev/null || EXT_PKGS_TO_INSTALL+=(gnome-shell-extension-user-theme)

if [ "${#EXT_PKGS_TO_INSTALL[@]}" -gt 0 ]; then
    sudo apt update -y
    sudo apt install -y "${EXT_PKGS_TO_INSTALL[@]}"
else
    echo "    [-] gnome-shell-ubuntu-extensions and gnome-shell-extension-user-theme already installed."
fi

# Remove any manually-installed (extensions.gnome.org) copy so the apt-managed
# one -- which registers its gsettings schema system-wide -- is authoritative.
MANUAL_USER_THEME_DIR="$HOME/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com"
if [ -d "$MANUAL_USER_THEME_DIR" ]; then
    rm -rf "$MANUAL_USER_THEME_DIR"
    echo "    [✓] Removed manually-installed user-theme extension in favor of the apt package."
fi

for uuid in ding@rastersoft.com ubuntu-dock@ubuntu.com tiling-assistant@ubuntu.com user-theme@gnome-shell-extensions.gcampax.github.com; do
    gnome-extensions enable "$uuid" 2>/dev/null || true
done
echo "    [✓] Enabled extensions: ding, ubuntu-dock, tiling-assistant, user-theme."

# ---------------------------------------------------------------------
# 7. APPEARANCE SETTINGS
# ---------------------------------------------------------------------
echo "--> Applying appearance settings..."

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Tahoe-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark'
gsettings set org.gnome.shell.extensions.user-theme name 'Tahoe-Dark'

# Screen lock: 20 minutes of idle time before the screen blanks/locks.
gsettings set org.gnome.desktop.session idle-delay 1200

gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.8
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.9
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false

gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'google-chrome.desktop', 'snap-store_snap-store.desktop', 'org.gnome.Yelp.desktop', 'code_code.desktop', 'org.gnome.Ptyxis.desktop']"

TAHOE_WALLPAPER="/usr/share/backgrounds/Tahoe/Tahoe-5k-dark.jpg"
if [ -f "$TAHOE_WALLPAPER" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$TAHOE_WALLPAPER"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$TAHOE_WALLPAPER"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$TAHOE_WALLPAPER"
    echo "    [✓] Wallpaper set to $TAHOE_WALLPAPER"
else
    echo "    [!] $TAHOE_WALLPAPER not found, skipping wallpaper gsettings."
fi

echo "    [✓] Appearance settings applied."

# ---------------------------------------------------------------------
# 8. DEV LANGUAGE TOOLING (Java, Node, Python)
# ---------------------------------------------------------------------
echo "--> Verifying dev language tooling..."

# JDKs for Gradle version switching (java17/java21/java25 in ubuntu-dot.bashrc).
# The apt default (currently OpenJDK 26 via update-alternatives) is left alone.
declare -a JDK_TO_INSTALL=()
for v in 17 21 25; do
    dpkg -s "openjdk-${v}-jdk" &> /dev/null || JDK_TO_INSTALL+=("openjdk-${v}-jdk")
done
if [ "${#JDK_TO_INSTALL[@]}" -gt 0 ]; then
    sudo apt update -y
    sudo apt install -y "${JDK_TO_INSTALL[@]}"
else
    echo "    [-] OpenJDK 17/21/25 already installed."
fi

# nvm
if [ ! -d "$HOME/.nvm" ]; then
    echo "    [+] Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
    echo "    [-] nvm already installed."
fi

# pyenv build dependencies (official pyenv suggested-build-environment for Debian/Ubuntu)
declare -a PYENV_DEPS=(libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev)
declare -a PYENV_DEPS_TO_INSTALL=()
for pkg in "${PYENV_DEPS[@]}"; do
    dpkg -s "$pkg" &> /dev/null || PYENV_DEPS_TO_INSTALL+=("$pkg")
done
if [ "${#PYENV_DEPS_TO_INSTALL[@]}" -gt 0 ]; then
    sudo apt update -y
    sudo apt install -y "${PYENV_DEPS_TO_INSTALL[@]}"
else
    echo "    [-] pyenv build dependencies already installed."
fi

# pyenv
if [ -d "$HOME/.pyenv/.git" ]; then
    git -C "$HOME/.pyenv" pull
elif [ ! -d "$HOME/.pyenv" ]; then
    echo "    [+] Installing pyenv..."
    git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
else
    echo "    [-] pyenv already present."
fi

# ---------------------------------------------------------------------
# 9. DOTFILE DEPLOYMENT
# ---------------------------------------------------------------------
echo "--> Deploying bash dotfiles..."

REPO_BASHRC="$REPO_DIR/env/bash/ubuntu-dot.bashrc"
HOME_BASHRC="$HOME/.bashrc"

if [ ! -f "$HOME_BASHRC" ] || [ "$REPO_BASHRC" -nt "$HOME_BASHRC" ]; then
    cp "$REPO_BASHRC" "$HOME_BASHRC"
    echo "    [✓] Deployed $REPO_BASHRC -> $HOME_BASHRC"
else
    echo "    [-] $HOME_BASHRC is already up to date."
fi

# ---------------------------------------------------------------------
# 10. SSH CONFIG FOR INTERNAL HOSTS (portainer / cloud)
# ---------------------------------------------------------------------
echo "--> Configuring SSH for portainer/cloud hosts..."

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
SSH_KNOWN_HOSTS="$SSH_DIR/known_hosts"
SSH_MARKER_BEGIN="# >>> profile-managed hosts (stapledon.ca) -- do not edit between markers >>>"
SSH_MARKER_END="# <<< profile-managed hosts (stapledon.ca) <<<"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

SSH_MANAGED_BLOCK="$(cat <<EOF
$SSH_MARKER_BEGIN
Host portainer.stapledon.ca portainer
  HostName portainer.stapledon.ca
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_kkdad

Host cloud.stapledon.ca cloud
  HostName cloud.stapledon.ca
  User root
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_kkdad
$SSH_MARKER_END
EOF
)"

if grep -qF "$SSH_MARKER_BEGIN" "$SSH_CONFIG"; then
    CURRENT_BLOCK="$(sed -n "/^${SSH_MARKER_BEGIN}\$/,/^${SSH_MARKER_END}\$/p" "$SSH_CONFIG")"
    if [ "$CURRENT_BLOCK" = "$SSH_MANAGED_BLOCK" ]; then
        echo "    [-] Managed SSH host entries already up to date."
    else
        sed -i "/^${SSH_MARKER_BEGIN}\$/,/^${SSH_MARKER_END}\$/d" "$SSH_CONFIG"
        printf '%s\n' "$SSH_MANAGED_BLOCK" >> "$SSH_CONFIG"
        echo "    [✓] Updated managed SSH host entries in $SSH_CONFIG"
    fi
else
    printf '\n%s\n' "$SSH_MANAGED_BLOCK" >> "$SSH_CONFIG"
    echo "    [✓] Added managed SSH host entries to $SSH_CONFIG"
fi

echo "--> Ensuring known_hosts entries for portainer/cloud..."
touch "$SSH_KNOWN_HOSTS"
for h in portainer.stapledon.ca cloud.stapledon.ca; do
    if ssh-keygen -F "$h" -f "$SSH_KNOWN_HOSTS" &> /dev/null; then
        echo "    [-] known_hosts already has an entry for $h."
    elif ssh-keyscan -H "$h" >> "$SSH_KNOWN_HOSTS" 2>/dev/null; then
        echo "    [✓] Added known_hosts entry for $h."
    else
        echo "    [!] Could not reach $h to scan its host key (offline?)."
    fi
done

echo "--> Ensuring stapledon.ca DNS search domain..."
if command -v nmcli &> /dev/null; then
    ACTIVE_CONN="$(nmcli -t -f NAME,DEVICE con show --active | grep -v '^lo:' | head -1 | cut -d: -f1)"
    if [ -n "$ACTIVE_CONN" ]; then
        CURRENT_SEARCH="$(nmcli -g ipv4.dns-search con show "$ACTIVE_CONN")"
        if [[ ",$CURRENT_SEARCH," == *",stapledon.ca,"* ]]; then
            echo "    [-] DNS search domain already includes stapledon.ca on $ACTIVE_CONN."
        else
            sudo nmcli con mod "$ACTIVE_CONN" +ipv4.dns-search stapledon.ca
            sudo nmcli con mod "$ACTIVE_CONN" +ipv6.dns-search stapledon.ca
            sudo nmcli con up "$ACTIVE_CONN" &> /dev/null
            echo "    [✓] Added stapledon.ca as DNS search domain on $ACTIVE_CONN."
        fi
    else
        echo "    [!] No active NetworkManager connection found, skipping DNS search domain."
    fi
else
    echo "    [-] NetworkManager (nmcli) not present, skipping DNS search domain."
fi

if [ -f "$SSH_DIR/id_kkdad" ]; then
    echo "    [-] ~/.ssh/id_kkdad already present."
else
    echo "    [!] ~/.ssh/id_kkdad not found -- SSH access to portainer.stapledon.ca / cloud.stapledon.ca (and the docker/podman remote context) won't authenticate until it's restored from your key backup. Not stored in this repo."
fi

# ---------------------------------------------------------------------
# 11. DOCKER / PODMAN REMOTE CONNECTIONS
# ---------------------------------------------------------------------
bash "$REPO_DIR/docker/setup.sh"

# ---------------------------------------------------------------------
# 12. PTYXIS TERMINAL PALETTE (synced from iTerm2)
# ---------------------------------------------------------------------
echo "--> Deploying iTerm2-synced Ptyxis palette..."

PTYXIS_PALETTE_DIR="$HOME/.local/share/ptyxis/palettes"
mkdir -p "$PTYXIS_PALETTE_DIR"
REPO_PALETTE="$REPO_DIR/ubuntu/iterm-sync.palette"
HOME_PALETTE="$PTYXIS_PALETTE_DIR/iterm-sync.palette"

if [ ! -f "$HOME_PALETTE" ] || [ "$REPO_PALETTE" -nt "$HOME_PALETTE" ]; then
    cp "$REPO_PALETTE" "$HOME_PALETTE"
    echo "    [✓] Deployed iTerm2-synced Ptyxis palette. Select 'iTerm2 Sync' in Ptyxis > Preferences > Profile > Palette."
else
    echo "    [-] Ptyxis palette already up to date."
fi

echo "===================================================="
echo " Setup complete! Run 'source ~/.bashrc' or open a new shell."
echo "===================================================="
