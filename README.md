# Wikipedia New Tab

A Chrome extension that replaces the new tab page with a single encyclopedia
entry — headword, gloss, a paragraph, a plate — and an obvious way into the
full article.

The design reference is a page from a printed encyclopedia volume, not a
newspaper front page: hairline rules, a portrait plate with a condensed
caption, and a thumb index on the right edge carrying the entry's first
letter and its page number.

## Install

1. `chrome://extensions`
2. Enable **Developer mode**
3. **Load unpacked** → select this directory

## How it works

`chrome.storage.local` is async, and a new tab that waits a frame for storage
is a new tab that flashes. So the queue lives in `localStorage`: eight
prepared entries, read synchronously and painted in the first script turn.
The network is never on the critical path.

- **Paint** — shift one entry off the queue, render, done.
- **Refill** — asynchronously, when the queue drops below four. One
  `generator=random` request returns a dozen entries at once.
- **Filter** — at write time, never at render time. Entries shorter than 300
  characters are stubs; sports seasons, squad lists and election tables are
  rejected by description. See `REJECT_DESCRIPTION` in `newtab.js` — that is
  the single knob for entry quality.
- **Offline** — the queue is the offline story. When it empties offline, the
  last entry returns with a quiet line. Fetch failures are never surfaced.

Entries without an image keep the column's width and simply leave it empty —
the text measure never shifts between tabs.

## Plates

The plate is small on purpose, a book plate rather than a hero: 152px, 4:5,
hairline rule, no shadow. Clicking it opens the photograph at viewport size.

Sizing has one non-obvious constraint. Commons thumbnail URLs carry their
width in the path, but **only a fixed set of widths exists** — 20, 40, 60,
120, 250, 330, 500, 960, 1280, 1920, 3840. Hotlinking any other width returns
a 400, not a smaller image ([T414805][t], [common thumbnail sizes][s]), so
rewriting a URL to `336px` produces a broken plate. `newtab.js` rounds up to
the nearest step, capped by the original's width so MediaWiki is never asked
for an upscale — except for SVGs, whose nominal width is not a resolution
limit.

[t]: https://phabricator.wikimedia.org/T414805
[s]: https://www.mediawiki.org/wiki/Common_thumbnail_sizes

## Interactions

| | |
| --- | --- |
| `R` / *Another entry* | next entry from the queue, no reload |
| Headword / *Read the full entry* | opens the article in the same tab |
| Click the plate | the photograph at viewport size; `Esc` or click closes |

## Files

```
manifest.json   MV3, chrome_url_overrides.newtab
newtab.html     static skeleton — JS fills text, never builds DOM
newtab.css      tokens, grid, thumb index, dark mode
newtab.js       queue, fetch, filters, render
fonts/          bundled woff2 (see fonts/README.md)
```

No permissions are requested. The Wikipedia API is called with `origin=*`,
which returns `Access-Control-Allow-Origin: *`, so no host permissions are
needed; the queue uses `localStorage`, so no `storage` permission is needed
either.
