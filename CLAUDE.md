# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```shell
npm install --legacy-peer-deps   # Install dependencies (--legacy-peer-deps required: grunt-load-options has stale peer dep)
npx grunt                        # Full build: jshint → browserify → uglify → cssmin → staticinline → clean → checksum
npx grunt jshint                 # Lint only
npx grunt browserify             # Bundle src/mobile/sgp.mobile.js → build/mobile.js
```

The built `index.html` (fully self-contained, all CSS/JS inlined) is committed to the repo. GitHub Pages serves it directly — no server-side build step.

## Architecture

A single-page client-side password generator. All password generation happens in-browser; nothing is stored or transmitted.

**Single deliverable:** `src/index.html` + `src/mobile/sgp.mobile.js` + `src/mobile/sgp.mobile.css` — built into a self-contained `index.html` at the repo root via `staticinline`.

**Build pipeline** (`grunt/tasks/aliases.js`):
1. `jshint` → lint (`grunt/options/jshint.js`)
2. `browserify` → bundle to `build/mobile.js`
3. `uglify` → minify to `build/mobile.min.js`
4. `cssmin` → minify to `build/mobile.min.css`
5. `staticinline` → inline both into `src/index.html` → `index.html`
6. `clean` → remove `build/` intermediates
7. `checksum` → write `checksums.json`

The Gruntfile is minimal — all config in `grunt/options/` (one file per plugin).

## Key details

- `supergenpass-lib` owns the password algorithm (MD5 or SHA512 → custom base64 → alphanumeric only)
- Output is always alphanumeric `[a-zA-Z0-9]`; the `Append %` option appends a literal `%` after generation
- Defaults: SHA512, 16 chars, Append % on — stored in `localStorage`; keys: `Len`, `Method`, `Salt`, `DisableTLD`, `DisableSpecialChar`, `Advanced`
- `noReferral` list in `sgp.mobile.js` blocks auto-populating the domain field from certain referrers
- Password length clamped to [4, 24] by `validatePasswordLength`
- Clipboard copy uses `navigator.clipboard.writeText` with `document.execCommand('copy')` fallback for HTTP contexts
- `/* jshint latedef: false */` is required in `grunt/tasks/checksum.js` to suppress a lint error in upstream code

## GitHub Actions

Two workflows in `.github/workflows/`:
- `build.yml` — runs on every push/PR: lint, build, verify committed `index.html` and `checksums.json` are unchanged
- `deploy.yml` — runs on push to main: uploads artifact and deploys to GitHub Pages

**Important:** Use `actions/deploy-pages@v4`, not `@v5`. v5 returns 401 on this repo (known regression). Pages is configured as `build_type: workflow`.

## Deploy

**GitHub Pages:** `https://sgp.geekosphere.net/` — served from the `main` branch via Actions workflow.

**Proxmox VE LXC:** `deploy/proxmox/create_lxc.sh` (run on PVE host) creates an Alpine LXC running nginx. `deploy/proxmox/install.sh` runs inside the container. The `update` command at `/bin/update` inside the container re-fetches and re-runs `install.sh`.

**Manual:** `deploy/nginx.conf` for self-hosted nginx. Blocks `src/`, `grunt/`, `test/`, `node_modules/`, `build/`, `deploy/` directories.

## GitHub accounts

This repo belongs to the personal account `geekosphere-net`. Always push with `git push origin main` — `origin` is set to `git@github.com.personal:geekosphere-net/supergenpass2.git`. The `gh` CLI defaults to the work account; run `gh auth switch --user geekosphere-net` before any `gh` commands targeting this repo.
