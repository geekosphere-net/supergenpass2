# supergenpass2

A personal fork of [SuperGenPass][sgp-upstream] — a client-side bookmarklet password generator. All password generation happens in-browser; nothing is ever stored or transmitted.

- **Live app:** https://geekosphere-net.github.io/supergenpass2/mobile/
- **Upstream algorithm:** [chriszarate/supergenpass-lib][sgp-lib]

## About

SuperGenPass transforms a master password + domain into a unique, complex password using MD5 or SHA512:

```
SuperGenPass("masterpassword:example1.com") // => zVNqyKdf7F
SuperGenPass("masterpassword:example2.com") // => eYPtU3mfVw
```

The bookmarklet injects a small overlay onto any page and populates password fields. The mobile/web app works standalone and is the primary interface.

## Develop locally

Requires [Grunt][grunt]:

```shell
git clone https://github.com/geekosphere-net/supergenpass2.git && cd supergenpass2
npm install
npm install -g grunt-cli
grunt   # full build: lint, bundle, minify, manifest, checksum
```

The built output (`mobile/index.html`, `bookmarklet/bookmarklet.min.js`) is committed so GitHub Pages can serve it without a CI build step.

## Deploy (home lab / LXC)

Copy the repo content to your web root and use the provided nginx config:

```shell
cp -r . /var/www/supergenpass2
cp deploy/nginx.conf /etc/nginx/sites-available/supergenpass2
ln -s /etc/nginx/sites-available/supergenpass2 /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

See `deploy/nginx.conf` for HTTPS configuration (fill in your cert paths and uncomment the HTTPS block).

## License

GNU General Public License version 2 — see [LICENSE](LICENSE).


[sgp-upstream]: https://github.com/chriszarate/supergenpass
[sgp-lib]: https://github.com/chriszarate/supergenpass-lib
[grunt]: http://gruntjs.com
