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

Images are preloaded as they enter the queue, requested at 2× and cropped 4:5.
Entries without an image keep the column's width and simply leave it empty —
the text measure never shifts between tabs.

## Interactions

| | |
| --- | --- |
| `R` / *Another entry* | next entry from the queue, no reload |
| Headword / *Read the full entry* | opens the article in the same tab |

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
