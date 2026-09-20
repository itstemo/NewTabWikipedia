# Wikipedia New Tab

A small monorepo for two ways to discover a random Wikipedia article:

- A Chrome MV3 extension that replaces every new tab with an encyclopedia entry.
- A native iOS app (SwiftUI) with a Home Screen widget.

Both follow the Barbechero design system — see `docs/design-system.md`.

## Repository layout

```text
apps/chrome-extension/   Chrome new-tab extension (dependency-free, no build)
apps/ios/                Native iOS app + WidgetKit extension
docs/                    Design tokens, screenshots
```

Each app owns its Wikipedia client — the extension's lives in `newtab.js`,
the iOS one in `apps/ios/Shared/WikipediaClient.swift`. They are deliberate
parallel implementations (the extension must stay dependency-free and paint
from synchronous `localStorage`); keep the reject filters and API params in
step when you change either.

## Prerequisites

- Google Chrome for the extension.
- Xcode 16+ and [XcodeGen](https://github.com/yonsm/XcodeGen)
  (`brew install xcodegen`) for the iOS app.
- Node.js for the test suite.

## Chrome extension

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Choose **Load unpacked**.
4. Select `apps/chrome-extension`.

The extension is deliberately dependency-free and uses a local queue so a new
tab can paint before the network responds. Its settings panel covers
appearance (device/light/dark), Wikipedia language, entry length, curated
and custom sections, and local progress counters.

For fast iteration without reloading the extension, serve the directory and
open `newtab.html` directly — the page uses no extension-only APIs:

```bash
cd apps/chrome-extension
python3 -m http.server
# open http://localhost:8000/newtab.html
```

`advance()`, `coldStart()` and `current` are reachable from the console.
`apps/chrome-extension/CLAUDE.md` documents the rules the page lives by —
read it before editing.

## iOS app

The Xcode project is generated from `apps/ios/project.yml` (gitignored):

```bash
cd apps/ios
xcodegen generate
open WikipediaNewTab.xcodeproj
```

Run the `WikipediaNewTab` scheme on a simulator or device. See
`apps/ios/README.md` for how the widget refreshes (it fetches its own
timelines — no app opens required), the App Group layout, and signing notes.

## Tests

```bash
npm test   # node:test suite covering the extension's API helpers
```

## Notes

- Wikipedia requests are made directly from the clients; no server or API key
  is required.
- iOS controls the exact timing of widget refreshes; the app sets the gap
  between articles.
