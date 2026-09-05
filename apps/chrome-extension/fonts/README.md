# Fonts

Two faces, bundled locally — a new tab must never wait on a font CDN.

Until the files are present, `newtab.css` falls through to system faces
(Iowan Old Style / Charter / Georgia, and Avenir Next Condensed). The layout
and metrics are unchanged; only the texture is.

Drop these in beside this file:

| File | Face | Used for |
| --- | --- | --- |
| `Newsreader.woff2` | Newsreader, variable (opsz 6–72, wght 400–600) | headword, body |
| `IBMPlexSansCondensed-Regular.woff2` | IBM Plex Sans Condensed 400 | gloss, caption, index |

Both are SIL Open Font License:

- Newsreader — https://github.com/productiontype/Newsreader
- IBM Plex Sans Condensed — https://github.com/IBM/plex

Subset to latin + latin-ext to keep the extension small.
