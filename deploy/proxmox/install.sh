#!/usr/bin/env sh
# SGP install script — runs inside the Alpine LXC
# Called by create_lxc.sh on first install; also invoked by the `update` command.
set -eu

REPO_URL="https://github.com/geekosphere-net/supergenpass2.git"
WWW_DIR="/var/www/sgp"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/geekosphere-net/supergenpass2/main/deploy/proxmox/install.sh"

# ── Packages ──────────────────────────────────────────────────────────────────
apk update --quiet
apk add --quiet --no-progress nginx git curl

# ── Clone or update repo ──────────────────────────────────────────────────────
if [ -d "$WWW_DIR/.git" ]; then
  git -C "$WWW_DIR" pull --quiet
else
  git clone --quiet --depth 1 "$REPO_URL" "$WWW_DIR"
fi

# ── nginx config ──────────────────────────────────────────────────────────────
cat > /etc/nginx/http.d/sgp.conf << 'NGINXCONF'
server {
    listen 80 default_server;
    server_name _;

    root /var/www/sgp;
    index index.html;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
    add_header Content-Security-Policy "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src 'self' data:; connect-src 'self';" always;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ ^/(src|grunt|test|node_modules|build|deploy)/ {
        deny all;
    }

    location ~ /\. {
        deny all;
    }
}
NGINXCONF

rm -f /etc/nginx/http.d/default.conf

# ── Enable and start nginx ────────────────────────────────────────────────────
rc-update add nginx default 2>/dev/null || true
rc-service nginx restart 2>/dev/null || rc-service nginx start

# ── Install the `update` command ──────────────────────────────────────────────
cat > /usr/local/bin/update << UPDATESCRIPT
#!/usr/bin/env sh
set -eu
echo "Updating SGP..."
curl -fsSL "$INSTALL_SCRIPT_URL" | sh
echo "Done."
UPDATESCRIPT

chmod +x /usr/local/bin/update
