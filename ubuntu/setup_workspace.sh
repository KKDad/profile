#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "===================================================="
echo " Starting Zorin OS / Ubuntu Idempotent Setup Script "
echo "===================================================="

# ---------------------------------------------------------------------
# 1. MAC LOOK & FEEL CONFIGURATION
# ---------------------------------------------------------------------
echo "--> Configuring macOS style layout behaviors..."

# Move window control buttons to top-left
CURRENT_LAYOUT=$(gsettings get org.gnome.desktop.wm.preferences button-layout)
if [ "$CURRENT_LAYOUT" != "'close,minimize,maximize:'" ]; then
    gsettings set org.gnome.desktop.interface gtk-key-theme "default"
    gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:"
    echo "    [✓] Moved window controls to top-left."
else
    echo "    [-] Window controls already in top-left."
fi

# Zorin-specific taskbar modifications (Checks if Zorin extension schema exists)
if gsettings list-schemas | grep -q "org.gnome.shell.extensions.zorin-dash"; then
    if [ "$(gsettings get org.gnome.shell.extensions.zorin-dash taskbar-alignment)" != "'center'" ]; then
        gsettings set org.gnome.shell.extensions.zorin-dash taskbar-alignment 'center'
    fi
    if [ "$(gsettings get org.gnome.shell.extensions.zorin-dash intellihide)" != "true" ]; then
        gsettings set org.gnome.shell.extensions.zorin-dash intellihide true
    fi
    if [ "$(gsettings get org.gnome.shell.extensions.zorin-dash icon-size)" != "40" ]; then
        gsettings set org.gnome.shell.extensions.zorin-dash icon-size 40
    fi
    echo "    [✓] Zorin taskbar tailored to Mac dock behavior."
else
    echo "    [-] Non-Zorin layout detected; skipping custom dash extensions."
fi

# ---------------------------------------------------------------------
# 2. RDP SERVER & PERSISTENT SESSION CONFIGURATION
# ---------------------------------------------------------------------
echo "--> Configuring Native RDP Server & Persistence Strategy..."

# Force GNOME to use Desktop Sharing (sharing the persistent active local session)
if gsettings list-schemas | grep -q "org.gnome.desktop.remote-desktop.rdp"; then
    gsettings set org.gnome.desktop.remote-desktop.rdp screen-share-mode 'mirror-primary'
fi

# Ensure RDP and control topology are explicitly enabled
grdctl rdp enable
grdctl rdp enable-control

# Dynamic and Idempotent Credential Prompting
# Checks if credentials exist by running a status verification check via grdctl
if grdctl rdp status | grep -q "Username:" && grdctl rdp status | grep -q "Credentials: set"; then
    echo "    [-] RDP credentials are already configured on this system."
    read -p "    [?] Do you want to overwrite the existing RDP credentials? (y/N): " OVERWRITE_CREDS
    OVERWRITE_CREDS=${OVERWRITE_CREDS:-n}
else
    OVERWRITE_CREDS="y"
fi

if [ "${OVERWRITE_CREDS,,}" = "y" ]; then
    echo "    [+] Setting up fresh RDP credentials..."
    read -p "    Enter RDP Username: " RDP_USER
    
    # Prompt for password securely masking the input characters
    unset RDP_PASS
    prompt="    Enter RDP Password: "
    while IFS= read -p "$prompt" -r -s -n 1 char; do
        if [[ $char == $'\0' || $char == $'\n' ]]; then
            break
        elif [[ $char == $'\177' || $char == $'\b' ]]; then
            if [ ${#RDP_PASS} -gt 0 ]; then
                RDP_PASS="${RDP_PASS%?}"
                echo -ne "\b \b"
            fi
        else
            RDP_PASS+="$char"
            echo -n "*"
        fi
        prompt=""
    done
    echo "" # Move to a clean new line after hidden input loop completes
    
    # Ensure variables aren't completely blank before passing to system
    if [ -z "$RDP_USER" ] || [ -z "$RDP_PASS" ]; then
        echo "    [!] Error: Username and Password cannot be blank. Skipping credential assignment."
    else
        grdctl rdp set-credentials "$RDP_USER" "$RDP_PASS"
        echo "    [✓] GNOME RDP credentials successfully configured."
    fi
fi

# Enable and kick-start user-space systemd service for GNOME RDP
if ! systemctl --user is-active --quiet gnome-remote-desktop; then
    systemctl --user enable gnome-remote-desktop
    systemctl --user start gnome-remote-desktop
    echo "    [✓] GNOME Remote Desktop service activated."
else
    echo "    [-] GNOME Remote Desktop service is already running."
fi

# -- XRDP PERSISTENT POLICY CHECK --
XRDP_SESMAN="/etc/xrdp/sesman.ini"
if [ -f "$XRDP_SESMAN" ]; then
    echo "    [+] xrdp detected. Checking session persistence policy..."
    if grep -q "^Policy=UBD" "$XRDP_SESMAN"; then
        echo "    [-] xrdp session policy is already set to UBD (Persistent)."
    else
        sudo sed -i 's/^Policy=.*/Policy=UBD/' "$XRDP_SESMAN"
        if ! grep -q "^Policy=UBD" "$XRDP_SESMAN"; then
            sudo sed -i '/\[Sessions\]/a Policy=UBD' "$XRDP_SESMAN"
        fi
        sudo systemctl restart xrdp
        echo "    [✓] Updated xrdp policy to UBD and restarted xrdp service."
    fi
fi

# ---------------------------------------------------------------------
# 3. IDEMPOTENT SOFTWARE INSTALLATION
# ---------------------------------------------------------------------
echo "--> Verifying packages and software suite..."

sudo apt update -y

# Git Setup
if ! command -v git &> /dev/null; then
    echo "    [+] Installing Git..."
    sudo apt install -y git
else
    echo "    [-] Git is already installed."
fi

# GitHub CLI (gh) Setup
if ! command -v gh &> /dev/null; then
    echo "    [+] Installing GitHub CLI (gh)..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
else
    echo "    [-] GitHub CLI (gh) is already installed."
fi

# Snap Package Helper for Desktop Apps
declare -A snaps=(
    ["code"]="VS Code"
    ["intellij-idea-community"]="IntelliJ IDEA Community" 
    ["ghostty"]="Ghostty Terminal (iTerm2 Cross-Platform Alt)"
)

for snap_pkg in "${!snaps[@]}"; do
    if ! snap list | grep -q "^$snap_pkg "; then
        echo "    [+] Installing ${snaps[$snap_pkg]}..."
        if [ "$snap_pkg" == "code" ] || [ "$snap_pkg" == "intellij-idea-community" ]; then
            sudo snap install "$snap_pkg" --classic
        else
            sudo snap install "$snap_pkg"
        fi
    else
        echo "    [-] ${snaps[$snap_pkg]} is already installed."
    fi
done

echo "===================================================="
echo " Setup complete! Your workspace is ready for RDP.   "
echo "===================================================="
