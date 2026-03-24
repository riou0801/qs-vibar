#!/usr/bin/env bash
set -euo pipefail

# deploy-greetd.sh — Deploy quickshell greetd-greeter config to /etc/greetd/
#
# Usage: sudo ./deploy-greetd.sh
#
# This script copies the quickshell greeter files to /etc/greetd/quickshell/
# so that the `greeter` user can access them, and updates sway-config accordingly.

GREETD_DIR="/etc/greetd"
QS_DEST="${GREETD_DIR}/quickshell"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Pre-flight checks ---

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

if ! id greeter &>/dev/null; then
    echo "ERROR: 'greeter' user does not exist. Install greetd first." >&2
    exit 1
fi

if [[ ! -d "${GREETD_DIR}" ]]; then
    echo "ERROR: ${GREETD_DIR} does not exist." >&2
    exit 1
fi

# --- Deploy quickshell config ---

echo "==> Deploying quickshell greeter to ${QS_DEST} ..."

mkdir -p "${QS_DEST}"

for f in greet.qml GreetContext.qml GreetSurface.qml; do
    if [[ ! -f "${SCRIPT_DIR}/${f}" ]]; then
        echo "ERROR: ${SCRIPT_DIR}/${f} not found." >&2
        exit 1
    fi
    cp -v "${SCRIPT_DIR}/${f}" "${QS_DEST}/${f}"
done

# --- Deploy wallpaper (if not already present) ---

WALLPAPER_SRC="/home/riou/.config/background/catppuccin_ekg_1.png"
WALLPAPER_DEST="${GREETD_DIR}/wallpaper.png"

if [[ -f "${WALLPAPER_SRC}" ]] && [[ ! -f "${WALLPAPER_DEST}" ]]; then
    echo "==> Copying wallpaper ..."
    cp -v "${WALLPAPER_SRC}" "${WALLPAPER_DEST}"
elif [[ -f "${WALLPAPER_DEST}" ]]; then
    echo "==> Wallpaper already exists at ${WALLPAPER_DEST}, skipping."
else
    echo "WARN: Wallpaper not found at ${WALLPAPER_SRC}, skipping."
fi

# --- Patch wallpaper path in deployed greet.qml ---
# Replace the home-directory wallpaper path with the deployed one

sed -i "s|/home/riou/.config/background/catppuccin_ekg_1.png|${WALLPAPER_DEST}|g" "${QS_DEST}/greet.qml"
echo "==> Patched wallpaper path in greet.qml -> ${WALLPAPER_DEST}"

# --- Write sway-config for greetd ---

SWAY_CONFIG="${GREETD_DIR}/sway-config"

echo "==> Writing ${SWAY_CONFIG} ..."
cat > "${SWAY_CONFIG}" << 'EOF'
# sway config for greetd greeter session
exec "quickshell -p /etc/greetd/quickshell/greet.qml; swaymsg exit"

bindsym Mod4+shift+e exec swaynag \
    -t warning \
    -m 'What do you want to do?' \
    -b 'Poweroff' 'systemctl poweroff' \
    -b 'Reboot' 'systemctl reboot'

include /etc/sway/config.d/*
EOF

# --- Fix permissions ---

echo "==> Setting permissions ..."
chown -R greeter:greeter "${QS_DEST}"
chmod -R u=rwX,go=rX "${QS_DEST}"
chown greeter:greeter "${WALLPAPER_DEST}" 2>/dev/null || true
chmod 644 "${WALLPAPER_DEST}" 2>/dev/null || true
chmod 644 "${SWAY_CONFIG}"

# --- Verify greetd config.toml ---

if ! grep -q 'sway --config /etc/greetd/sway-config' "${GREETD_DIR}/config.toml"; then
    echo ""
    echo "WARN: /etc/greetd/config.toml may not be configured correctly."
    echo "      Ensure [default_session] contains:"
    echo ""
    echo '      command = "sway --config /etc/greetd/sway-config"'
    echo '      user = "greeter"'
    echo ""
fi

echo ""
echo "==> Done! Greeter deployed to ${QS_DEST}"
echo ""
echo "    Config files:"
echo "      ${QS_DEST}/greet.qml"
echo "      ${QS_DEST}/GreetContext.qml"
echo "      ${QS_DEST}/GreetSurface.qml"
echo "      ${SWAY_CONFIG}"
echo "      ${WALLPAPER_DEST}"
echo ""
echo "    To test: sudo greetd"
echo "    To enable: sudo systemctl enable greetd"
