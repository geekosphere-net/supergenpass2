# supergenpass2

A personal fork of [SuperGenPass][sgp-upstream] — a client-side password generator. All password generation happens in-browser; nothing is ever stored or transmitted.

- **Live app:** https://sgp.geekosphere.net/
- **Upstream algorithm:** [chriszarate/supergenpass-lib][sgp-lib]

## About

SuperGenPass transforms a master password + domain into a unique, complex password using MD5 or SHA512:

```
SuperGenPass("masterpassword:example1.com") // => zVNqyKdf7F
SuperGenPass("masterpassword:example2.com") // => eYPtU3mfVw
```

## Develop locally

Requires [Grunt][grunt]:

```shell
git clone https://github.com/geekosphere-net/supergenpass2.git && cd supergenpass2
npm install
npm install -g grunt-cli
grunt   # full build: lint, bundle, minify, checksum
```

The built output (`index.html`) is committed so GitHub Pages can serve it without a CI build step.

## Deploy on Proxmox VE (LXC)

Run this on your PVE host — creates an Alpine Linux LXC (~128 MB RAM, 1 GB disk) running nginx:

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/geekosphere-net/supergenpass2/main/deploy/proxmox/create_lxc.sh)
```

**Default container settings** (override with environment variables):

| Variable | Default | Example override |
|----------|---------|-----------------|
| `CT_ID` | next available | `CT_ID=210` |
| `CT_HOSTNAME` | `sgp` | `CT_HOSTNAME=sgp` |
| `CT_MEMORY` | `128` MB | `CT_MEMORY=64` |
| `CT_DISK_SIZE` | `1` GB | `CT_DISK_SIZE=2` |
| `CT_STORAGE` | `local-lvm` | `CT_STORAGE=local` |
| `CT_BRIDGE` | `vmbr0` | `CT_BRIDGE=vmbr1` |
| `CT_IP` | `dhcp` | `CT_IP=192.168.1.50/24` |
| `CT_GW` | _(none)_ | `CT_GW=192.168.1.1` |

Example with a static IP:

```shell
CT_IP="192.168.1.50/24" CT_GW="192.168.1.1" CT_STORAGE="local" \
  bash <(curl -fsSL https://raw.githubusercontent.com/geekosphere-net/supergenpass2/main/deploy/proxmox/create_lxc.sh)
```

To update the app, run inside the container:

```shell
update
```

Or from the PVE host without entering the container:

```shell
pct exec <CT_ID> -- update
```

## Deploy (manual / other hosts)

Copy the repo content to your web root and use the provided nginx config:

```shell
cp -r . /var/www/sgp
cp deploy/nginx.conf /etc/nginx/sites-available/sgp
ln -s /etc/nginx/sites-available/sgp /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

See `deploy/nginx.conf` for HTTPS configuration (fill in your cert paths and uncomment the HTTPS block).

## License

GNU General Public License version 2 — see [LICENSE](LICENSE).


[sgp-upstream]: https://github.com/chriszarate/supergenpass
[sgp-lib]: https://github.com/chriszarate/supergenpass-lib
[grunt]: http://gruntjs.com
