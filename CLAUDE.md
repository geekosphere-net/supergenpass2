# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```shell
npm install        # Install dependencies
grunt              # Full build: lint → bundle → minify → test → manifest → checksum
grunt jshint       # Lint only
grunt qunit        # Run QUnit tests only (browser-based, via PhantomJS)
grunt browserify   # Bundle src/mobile/*.js → build/mobile.js
```

The `npm test` script runs `grunt qunit` and then Intern integration tests (Intern tests only run on CI, not pull requests).

## Architecture

SuperGenPass has two deliverables built from `src/`:

**Bookmarklet** (`src/bookmarklet/sgp.bookmarklet.js`) — Injected into arbitrary third-party pages. Uses jQuery (loaded dynamically if absent). Opens an iframe pointing at the mobile app, establishes a `postMessage` channel to receive generated passwords, and populates visible `<input type="password">` fields. The iframe is a draggable overlay anchored to the top-right of the largest local frame found on the page.

**Mobile/web app** (`src/mobile/sgp.mobile.js` + `src/mobile/index.html`) — A self-contained Browserify bundle (`build/mobile.js` → `build/mobile.min.js`). Depends on `supergenpass-lib` for the actual hash algorithm (MD5 or SHA512), `crypto-js` for identicons, and jQuery for DOM. Persists user preferences (length, secret, hash method, subdomain stripping) in `localStorage`. Communicates back to the bookmarklet via `postMessage` — sending the generated password and document height.

**Build pipeline** (Grunt, configured entirely in `grunt/options/*.js` and `grunt/tasks/aliases.js`):
1. `jshint` → lint
2. `browserify` → bundle mobile app to `build/mobile.js`
3. `uglify` → minify to `build/mobile.min.js`
4. `cssmin` → minify CSS
5. `staticinline` → inline assets into HTML
6. `bookmarklet` → wrap bookmarklet source into a `javascript:` URI
7. `template` → render `src/homepage/index.html.tmpl` → `index.html`
8. `clean` → remove intermediate build artifacts
9. `qunit` → run browser tests against `test/qunit/*.html`
10. `manifest` → generate AppCache manifest for mobile offline use
11. `checksum` → write `checksums.json`

The Gruntfile itself is minimal (`Gruntfile.js`) — all task configuration lives in `grunt/options/` (one file per plugin) and aliases in `grunt/tasks/aliases.js`.

## Key details

- The `supergenpass-lib` package owns the password generation algorithm; this repo only provides the UI.
- `noReferral` list in `sgp.mobile.js` controls which referrer hostnames are blocked from auto-populating the domain field.
- Password length is clamped to [4, 24] by `validatePasswordLength`; values outside that range are silently coerced.
- Tests in `test/qunit/mobile.js` drive the mobile app through an iframe using DOM events and assert on `#Output` text content.
