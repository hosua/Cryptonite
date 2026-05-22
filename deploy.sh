#!/bin/bash
set -e

DEV_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DEST="$HOME/pkgs/third-party/KWidgets/cryptonite.plasmoid"
PLASMOID_ID="org.kde.plasma.cryptonite"
WORK_DIR="$(mktemp -d)"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "==> Building package structure..."
mkdir -p "$WORK_DIR/contents/ui"
mkdir -p "$WORK_DIR/contents/config"
mkdir -p "$WORK_DIR/contents/code"
mkdir -p "$WORK_DIR/contents/images"
mkdir -p "$WORK_DIR/translate"

cp "$DEV_DIR/metadata.json" "$WORK_DIR/"

# UI
for f in main.qml ColorChooser.qml ConfigAbout.qml ConfigGeneral.qml \
          ConfigNotifications.qml CryptoEngine.qml HelpButton.qml SoundPlayer.qml; do
    cp "$DEV_DIR/$f" "$WORK_DIR/contents/ui/$f"
done

# Config
cp "$DEV_DIR/config.qml" "$WORK_DIR/contents/config/config.qml"
cp "$DEV_DIR/main.xml"   "$WORK_DIR/contents/config/main.xml"

# Code
cp "$DEV_DIR/datafetcher.js" "$WORK_DIR/contents/code/datafetcher.js"

# Images
cp "$DEV_DIR/crypto.jpg" "$WORK_DIR/contents/images/crypto.jpg"

# Translations
cp "$DEV_DIR/de.po" "$WORK_DIR/translate/de.po"

echo "==> Packaging to $PKG_DEST..."
(cd "$WORK_DIR" && zip -r "$PKG_DEST" . -x "*.DS_Store")

echo "==> Removing existing installation..."
kpackagetool6 --type Plasma/Applet --remove "$PLASMOID_ID" 2>/dev/null || true
rm -rf "$HOME/.local/share/kpackage/generic/cryptonite"

echo "==> Installing..."
kpackagetool6 --type Plasma/Applet -i "$PKG_DEST"

echo ""
read -rp "Restart plasmashell now? [Y/n] " answer
if [[ "${answer,,}" != "n" ]]; then
    echo "==> Restarting plasmashell..."
    plasmashell --replace &
fi
