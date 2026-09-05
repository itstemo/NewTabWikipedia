# CLAUDE.md

A Chrome MV3 extension that replaces the new tab page with one Wikipedia
entry, set like a page from a printed encyclopedia. Four files, no build step,
no dependencies: `manifest.json`, `newtab.html`, `newtab.css`, `newtab.js`.

## The one rule

**The page must paint the instant the tab opens.** Every design decision below
follows from that, and a change that puts anything between load and first
paint is a regression even if it looks better.

Consequences worth knowing before you edit:

- **`localStorage`, not `chrome.storage.local`.** The queue is read
  synchronously in the first script turn. `chrome.storage` is promise-based
  and costs a frame of empty page on every tab. Do not "modernise" this.
- **The network is never on the critical path.** `boot()` paints from the
  queue and only then tops it up. The one exception is `coldStart()`, on first
  install or an empty queue.
- **`newtab.html` is a complete static skeleton.** JS fills text nodes and
  attributes; it never builds DOM. First paint has final geometry.
- **Filters run at write time**, as entries enter the queue — never at render.
  The render path never blocks, retries, or discards.
- **Failures are silent.** A new tab must never show an error. Fetch failures
  fall back to the queue, then to the last entry with a quiet notice.

## Two bugs that keep coming back

**1. `[hidden]` loses to `display`.** Both the plate `<img>` and its wrapping
button carry `hidden`, and both have a `display` rule. Without an explicit
`[hidden] { display: none }` at equal-or-higher specificity, an entry with no
plate draws an empty bordered rectangle, and a failed image shows a broken
icon the error handler cannot hide. This has been introduced twice.

**2. Commons thumbnails only exist at eleven widths** — 20, 40, 60, 120, 250,
330, 500, 960, 1280, 1920, 3840. Hotlinking any other width returns **400,
not a smaller image** ([T414805][t], [common thumbnail sizes][s]). Rewriting a
URL to `336px` yields a broken plate, not a crisp one. `STEPS` and `step()` in
`newtab.js` own this; go through them for any image URL. Two riders:

- Cap the request by `original.width` — MediaWiki will serve an upscale, and
  an upscale is exactly what makes a plate look pixelated.
- **Except for SVGs**, where `original.width` is a nominal vector dimension
  (Antalarmin reports 160) and not a resolution limit. Hence `entry.vector`.

[t]: https://phabricator.wikimedia.org/T414805
[s]: https://www.mediawiki.org/wiki/Common_thumbnail_sizes

## Data

One request to `action=query&generator=random` returns ~12 entries with title,
description, extract, thumbnail, original dimensions, pageid and canonical
URL. Prefer it to `/page/random/summary`, which costs one round trip per entry.

No permissions are declared, and it should stay that way: `origin=*` gets
`Access-Control-Allow-Origin: *`, and `localStorage` needs no `storage`
permission.

`description` is the quiet win in the data — a typographically distinct
second line on nearly every entry, for free. It is the gloss, and *only* the
gloss; it was also the plate caption once, which just printed the same words
twice under the image.

## Entry quality is the open problem

Random Wikipedia is mostly sports seasons, squad lists, election tables and
one-line athlete stubs. `MIN_EXTRACT` does not catch them — a group-stage
results table clears 500 characters easily. `REJECT_DESCRIPTION` in
`newtab.js` is the single knob, and it is a blocklist, which means it loses
over time.

The structural fix, not yet done: draw from a curated pool (Wikipedia's Vital
Articles level 4 is ~10,000 genuinely encyclopedic entries) and use pure
random only to top up. It is a contained change to `apiUrl()`.

## Design

The reference is a printed encyclopedia volume, not a newspaper. Hairline
rules, no shadows, no border radius, no entrance animation on text —
animating it would literally make the page slower to read.

- **The plate is a plate**, 152px and 4:5, not a hero image. Full resolution
  lives behind a click, in a `<dialog>` (which gives Escape and focus
  containment for free), loaded on click and never before.
- **The plate column holds its width when empty.** The text measure must not
  shift between tabs. Text-only entries are a quieter variant, not a bug.
- **The measure is `--measure: 540px`, in px deliberately.** `ch` resolves
  against the parent's font, not the face the paragraph is set in, which
  silently collapsed the column to ~45 characters.
- **The head spans both columns** so the rule runs the full page width and the
  plate's top edge meets the first line of the paragraph regardless of how the
  headword wraps. The plate's 6px offset is half the body leading — it lands
  the top edge on the cap height rather than the em box.
- **`<meta name="color-scheme">` is load-bearing.** Without it every tab
  flashes white in dark mode before the CSS lands.
- **Fonts are bundled, never a CDN** (see `fonts/README.md`). A new tab must
  not wait on the network, and a font swap 40 times a day is intolerable.
  Absent the files, the stacks fall through to system faces.

## Working on it

Load unpacked from `chrome://extensions` with developer mode on.

For iteration, `python3 -m http.server` and open `newtab.html` directly — the
page has no extension-only APIs, so everything but the newtab override works.
`advance()`, `coldStart()` and `current` are reachable from the console, which
is the fastest way to reach a specific state (a text-only entry, a stale
entry, a given article).

Verify image work against real URLs before believing it. A plate that 400s
looks identical to one that is merely slow, and the failure is invisible in
the happy path.
