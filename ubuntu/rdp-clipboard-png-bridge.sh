#!/usr/bin/env bash
# Invoked by `wl-paste --watch` on every Wayland clipboard change.
#
# gnome-remote-desktop's RDP clipboard bridge only ever offers copied images
# as image/bmp (converted from Windows' CF_DIB format), regardless of what
# the RDP client copied. Tools that only recognize web image types -- like
# Claude Code's terminal image paste, which needs a format the Claude API
# accepts (png/jpeg/gif/webp) -- see no image at all. Mirror BMP-only
# clipboard entries as PNG too so those tools can see them.
set -euo pipefail

types="$(wl-paste --list-types 2>/dev/null || true)"

if grep -qx 'image/bmp' <<<"$types" && ! grep -qx 'image/png' <<<"$types"; then
    wl-paste --type image/bmp | python3 -c '
import sys, io
from PIL import Image
Image.open(io.BytesIO(sys.stdin.buffer.read())).save(sys.stdout.buffer, format="PNG")
' | wl-copy --type image/png
fi
