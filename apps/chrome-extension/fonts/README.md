# Fonts

Two faces, bundled locally — a new tab must never wait on a font CDN. From
the Barbechero manual (see `docs/design-system.md` at the repo root):

| Face | Weights | Used for |
| --- | --- | --- |
| Spectral | 300 light · 400 regular + italic · 600 semibold | headword, body, gloss (italic) |
| IBM Plex Mono | 400 · 500 | kickers, labels, buttons, index, stats |

Each face ships as latin + latin-ext `.woff2` subsets
(`<Family>-<weight>[i]-<subset>.woff2`) with `unicode-range` in
`newtab.css` — the browser fetches only the subset a page needs.

Both are SIL Open Font License, from the google/fonts repo:

- Spectral — https://github.com/google/fonts/tree/main/ofl/spectral
- IBM Plex Mono — https://github.com/google/fonts/tree/main/ofl/ibmplexmono

The iOS app uses the same faces as TTF (see `apps/ios`).
