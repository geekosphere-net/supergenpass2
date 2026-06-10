#!/usr/bin/env bash
# SGP (SuperGenPass) LXC installer for Proxmox VE
# Run on your PVE host:
#   bash <(curl -fsSL https://raw.githubusercontent.com/geekosphere-net/supergenpass2/main/deploy/proxmox/create_lxc.sh)

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="  "
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info()  { local msg="$1"; echo -ne "  ${HOLD} ${YW}${msg}...${CL}"; }
msg_ok()    { local msg="$1"; echo -e "${BFR}  ${CM} ${GN}${msg}${CL}"; }
msg_error() { local msg="$1"; echo -e "${BFR}  ${CROSS} ${RD}${msg}${CL}"; exit 1; }

header_info() {
  clear
  cat <<"EOF"
   _____ _____ ____
  / ___// ___// __ \
  \__ \/ (_ // /_/ /
 ___/ / /_/ / ____/
/____/\____/_/      LXC Installer for Proxmox VE

EOF
}

# ── Defaults (override with env vars before running) ─────────────────────────
CT_ID="${CT_ID:-$(pvesh get /cluster/nextid 2>/dev/null || echo 200)}"
CT_HOSTNAME="${CT_HOSTNAME:-sgp}"
CT_MEMORY="${CT_MEMORY:-128}"      # MB — nginx + static files needs almost nothing
CT_DISK_SIZE="${CT_DISK_SIZE:-1}"  # GB
CT_CORES="${CT_CORES:-1}"
CT_STORAGE="${CT_STORAGE:-local-lvm}"
CT_BRIDGE="${CT_BRIDGE:-vmbr0}"
CT_IP="${CT_IP:-dhcp}"             # static example: "192.168.1.50/24"
CT_GW="${CT_GW:-}"                 # required when CT_IP is static
CT_DNS="${CT_DNS:-8.8.8.8}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
UNPRIVILEGED=1

INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/geekosphere-net/supergenpass2/main/deploy/proxmox/install.sh"

# ── Preflight ─────────────────────────────────────────────────────────────────
header_info

if ! command -v pveversion &>/dev/null; then
  msg_error "This script must be run on a Proxmox VE host"
fi

if pct status "$CT_ID" &>/dev/null; then
  msg_error "Container ID ${CT_ID} already exists. Set a different CT_ID and retry."
fi

# ── Find latest Alpine template ───────────────────────────────────────────────
msg_info "Locating Alpine Linux template"
TEMPLATE=$(pveam available --section system 2>/dev/null \
  | awk '{print $2}' \
  | grep "^alpine-3\." \
  | grep "amd64" \
  | sort -V | tail -1)

if [[ -z "$TEMPLATE" ]]; then
  msg_error "Could not find an Alpine template. Run: pveam update"
fi
msg_ok "Found template: ${TEMPLATE}"

# Download template if not already cached
if ! pveam list "$TEMPLATE_STORAGE" 2>/dev/null | grep -q "$TEMPLATE"; then
  msg_info "Downloading ${TEMPLATE}"
  pveam download "$TEMPLATE_STORAGE" "$TEMPLATE" &>/dev/null
  msg_ok "Downloaded ${TEMPLATE}"
fi

# ── Build network config string ───────────────────────────────────────────────
if [[ "$CT_IP" == "dhcp" ]]; then
  NET_CONFIG="ip=dhcp"
else
  NET_CONFIG="ip=${CT_IP}"
  [[ -n "$CT_GW" ]] && NET_CONFIG="${NET_CONFIG},gw=${CT_GW}"
fi

# ── Create container ──────────────────────────────────────────────────────────
msg_info "Creating LXC container ${CT_ID} (${CT_HOSTNAME})"
pct create "$CT_ID" \
  "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" \
  --arch amd64 \
  --ostype alpine \
  --hostname "$CT_HOSTNAME" \
  --cores "$CT_CORES" \
  --memory "$CT_MEMORY" \
  --net0 "name=eth0,bridge=${CT_BRIDGE},${NET_CONFIG}" \
  --rootfs "${CT_STORAGE}:${CT_DISK_SIZE}" \
  --unprivileged "$UNPRIVILEGED" \
  --features nesting=0 \
  --nameserver "$CT_DNS" \
  --onboot 1 \
  --start 0 &>/dev/null
msg_ok "Container ${CT_ID} created"

# ── Start container ───────────────────────────────────────────────────────────
msg_info "Starting container"
pct start "$CT_ID"
sleep 3  # give Alpine a moment to init networking
msg_ok "Container started"

# ── Run install script inside the container ───────────────────────────────────
msg_info "Running install script"
pct exec "$CT_ID" -- sh -c \
  "apk add --quiet --no-progress curl 2>/dev/null; curl -fsSL '${INSTALL_SCRIPT_URL}' | sh" \
  &>/dev/null
msg_ok "Install complete"

# ── Report ────────────────────────────────────────────────────────────────────
IP=$(pct exec "$CT_ID" -- sh -c "ip -4 addr show eth0 | grep -oP '(?<=inet )[^/]+'" 2>/dev/null || echo "<pending>")

echo ""
echo -e "  ${GN}SGP is running.${CL}"
echo -e "  LXC ID   : ${YW}${CT_ID}${CL}"
echo -e "  Hostname : ${YW}${CT_HOSTNAME}${CL}"
echo -e "  IP       : ${YW}${IP}${CL}"
echo -e "  URL      : ${YW}http://${IP}/${CL}"
echo ""
echo -e "  To update, run inside the container: ${YW}update${CL}"
echo -e "  Or from the PVE host:                ${YW}pct exec ${CT_ID} -- update${CL}"
echo ""
