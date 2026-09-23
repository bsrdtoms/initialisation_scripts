#!/bin/bash
# =============================================================================
# Script d'initialisation Onyxia / SSP Cloud
# Reconstruit un poste "Claude Desktop" complet dans un service code-server :
#   - pile graphique headless  : Xvfb + fluxbox + x11vnc + websockify/noVNC
#   - Claude Desktop for Linux : depot apt officiel downloads.claude.ai
#   - Google Chrome            : pour ouvrir les liens depuis Claude Desktop
#   - tout est reinstallable hors ligne au demarrage suivant grace aux caches
#     de paquets .deb conserves dans /home/onyxia/work (seul dossier persistant)
#
# Acces a l'interface : https://<domaine-du-service>/proxy/6080/vnc.html
# Log d'installation  : /home/onyxia/work/claude-desktop/init.log
# Relance manuelle    : bash /home/onyxia/work/claude-desktop/run.sh
# =============================================================================
set -u

WORK=/home/onyxia/work/claude-desktop
RUN="$WORK/run.sh"

mkdir -p "$WORK/debs/partial" "$WORK/browser-debs/partial" "$WORK/profile" "$WORK/chrome-profile"

# --- run.sh : script idempotent d'installation + demarrage ------------------
cat > "$RUN" <<'RUNEOF'
#!/usr/bin/env bash
set -e
WORK=/home/onyxia/work/claude-desktop
export DEBIAN_FRONTEND=noninteractive
KEYRING=/usr/share/keyrings/claude-desktop-archive-keyring.asc
FPR=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
PKGS="xvfb x11vnc fluxbox novnc websockify xterm dbus-x11 curl gnupg wmctrl x11-utils libsecret-1-0"
SUDO=sudo
[ "$(id -u)" = 0 ] && SUDO=""

need_install() {
  ! command -v claude-desktop >/dev/null 2>&1 ||
  ! command -v Xvfb          >/dev/null 2>&1 ||
  ! command -v websockify    >/dev/null 2>&1
}

# --- 1. paquets -------------------------------------------------------------
if need_install && ls "$WORK"/debs/*.deb >/dev/null 2>&1; then
  echo "[1/3] installation hors-ligne depuis le cache .deb"
  $SUDO dpkg -i "$WORK"/debs/*.deb > /tmp/dpkg.log 2>&1 || $SUDO apt-get -y -f install
fi

if need_install; then
  echo "[1/3] installation depuis les depots (les .deb sont mis en cache dans work)"
  mkdir -p "$WORK/debs/partial"
  APTCACHE="-o Dir::Cache::archives=$WORK/debs"
  $SUDO apt-get update -qq
  $SUDO apt-get $APTCACHE install -y --no-install-recommends $PKGS
  $SUDO curl -fsSLo "$KEYRING" https://downloads.claude.ai/claude-desktop/key.asc
  gpg --show-keys "$KEYRING" | tr -d ' ' | grep -q "$FPR"
  echo "deb [arch=amd64,arm64 signed-by=$KEYRING] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    | $SUDO tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get $APTCACHE install -y --no-install-recommends claude-desktop
  $SUDO rm -rf "$WORK/debs/partial" "$WORK/debs/lock"
  $SUDO chown -R "$(id -u):$(id -g)" "$WORK/debs" 2>/dev/null || true
fi

# --- 2. Google Chrome (pour ouvrir les liens depuis Claude Desktop) --------
install_chrome_from_cache() {
  echo "[2/4] Google Chrome : installation hors-ligne depuis le cache .deb"
  $SUDO dpkg -i "$WORK"/browser-debs/*.deb > /tmp/dpkg-chrome.log 2>&1 || $SUDO apt-get -y -f install
}

install_chrome_from_web() {
  echo "[2/4] Google Chrome : telechargement + installation"
  mkdir -p "$WORK/browser-debs/partial"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSLo "$tmp/google-chrome-stable_current_amd64.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  $SUDO dpkg -i "$tmp/google-chrome-stable_current_amd64.deb" > /tmp/dpkg-chrome.log 2>&1 \
    || $SUDO apt-get -o Dir::Cache::archives="$WORK/browser-debs" -y -f install
  cp -n "$tmp/google-chrome-stable_current_amd64.deb" "$WORK/browser-debs/" 2>/dev/null || true
  rm -rf "$tmp" "$WORK/browser-debs/partial" "$WORK/browser-debs/lock"
  $SUDO chown -R "$(id -u):$(id -g)" "$WORK/browser-debs" 2>/dev/null || true
}

if ! command -v google-chrome-stable >/dev/null; then
  if ls "$WORK"/browser-debs/*.deb >/dev/null 2>&1; then install_chrome_from_cache; fi
  command -v google-chrome-stable >/dev/null || install_chrome_from_web
fi

# --- 3. profils persistants (Claude + Chrome) -------------------------------
echo "[3/4] profils persistants"
mkdir -p "$WORK/profile" "$WORK/chrome-profile" "$HOME/.config"
if [ -e "$HOME/.config/Claude" ] && [ ! -L "$HOME/.config/Claude" ]; then
  mv "$HOME/.config/Claude" "$HOME/.config/Claude.bak.$(date +%s)"
fi
ln -sfn "$WORK/profile" "$HOME/.config/Claude"
if [ -e "$HOME/.config/google-chrome" ] && [ ! -L "$HOME/.config/google-chrome" ]; then
  mv "$HOME/.config/google-chrome" "$HOME/.config/google-chrome.bak.$(date +%s)"
fi
ln -sfn "$WORK/chrome-profile" "$HOME/.config/google-chrome"

# --- 3bis. Claude Code CLI : restauration depuis un secret Vault Onyxia -----
# Si le secret "Mes secrets" a ete injecte comme variable d'environnement
# (valeur = contenu de ~/.claude.json encode en base64), on le materialise ici.
# Ne remplace jamais un ~/.claude.json deja present (evite d'ecraser une
# session locale plus recente par une copie potentiellement perimee).
if [ ! -s "$HOME/.claude.json" ] && [ -n "${CLAUDE_CODE_JSON_B64:-}" ]; then
  echo "[3bis/4] restauration de ~/.claude.json depuis le secret Vault CLAUDE_CODE_JSON_B64"
  echo "$CLAUDE_CODE_JSON_B64" | base64 -d > "$HOME/.claude.json" 2>/tmp/claude-json-restore.log \
    && chmod 600 "$HOME/.claude.json" \
    || echo "  echec du decodage, voir /tmp/claude-json-restore.log"
fi

# --- 4. pile graphique + Claude Desktop + Chrome ----------------------------
echo "[4/4] demarrage de la pile graphique"
export DISPLAY=:1
pkill -f "Xvfb :1" || true
pkill -f x11vnc || true
pkill -f websockify || true
pkill -f /usr/lib/claude-desktop || true
pkill -f /usr/bin/claude-desktop || true
pkill -f /opt/google/chrome/chrome || true
sleep 2
Xvfb :1 -screen 0 1600x900x24 >/tmp/xvfb.log 2>&1 &
sleep 2
fluxbox >/tmp/fluxbox.log 2>&1 &
x11vnc -display :1 -forever -shared -nopw -rfbport 5901 >/tmp/x11vnc.log 2>&1 &
sleep 2
websockify --web=/usr/share/novnc 6080 localhost:5901 >/tmp/novnc.log 2>&1 &
sleep 3
setsid dbus-run-session -- claude-desktop --password-store=basic < /dev/null > /tmp/claude.log 2>&1 &
sleep 20
setsid google-chrome-stable --no-sandbox --password-store=basic < /dev/null > /tmp/chrome.log 2>&1 &
sleep 5
echo "NPROC=$(pgrep -cf /usr/lib/claude-desktop)"
echo "NPROC_CHROME=$(pgrep -cf /opt/google/chrome/chrome)"
if [ -n "${VSCODE_PROXY_URI:-}" ]; then
  echo "URL: $(echo "$VSCODE_PROXY_URI" | sed 's|{{port}}|6080|')vnc.html?path=proxy/6080/websockify&autoconnect=true&resize=remote"
else
  echo "URL: https://<domaine-du-service>/proxy/6080/vnc.html?path=proxy/6080/websockify&autoconnect=true&resize=remote"
fi
RUNEOF

chmod +x "$RUN"
chown -R onyxia:users /home/onyxia/work/claude-desktop 2>/dev/null || \
  chown -R onyxia:onyxia /home/onyxia/work/claude-desktop 2>/dev/null || true

# --- lancement en arriere-plan pour ne pas retarder le demarrage du service --
if [ "$(id -u)" = 0 ]; then
  setsid runuser -l onyxia -c "bash $RUN" < /dev/null > "$WORK/init.log" 2>&1 &
else
  setsid bash "$RUN" < /dev/null > "$WORK/init.log" 2>&1 &
fi

echo "Claude Desktop : installation lancee en arriere-plan (voir $WORK/init.log)"
exit 0
