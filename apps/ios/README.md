# Wikipedia New Tab for iOS

Native SwiftUI app + WidgetKit extension. No third-party dependencies.

```text
App/        SwiftUI app — article view, plate zoom, in-app Safari, settings, stats
Widget/     WidgetKit extension — small and medium Home Screen widgets
Shared/     Wikipedia client, filters, App Group store (compiled into both targets)
Resources/  Spectral + IBM Plex Mono (TTF), asset catalog
project.yml XcodeGen spec — the source of truth for the project
```

Feature map, matching the extension: refresh is the ↻ button or
pull-to-refresh; the plate zooms full-screen on tap (pinch + double-tap);
"Read the full entry" opens in an in-app Safari sheet with reader mode;
settings control appearance, language, sections, entry length and widget
cadence; progress counters live at the bottom of Settings.

## Setup

The `.xcodeproj` is generated and gitignored:

```bash
brew install xcodegen
xcodegen generate
open WikipediaNewTab.xcodeproj
```

Build and run the `WikipediaNewTab` scheme in a simulator or on a device.
The `WikipediaWidget` scheme runs the extension directly (choose the widget
host when prompted) if you want to iterate on the widget alone.

Requires Xcode 16+ and iOS 17+. Simulator builds need no signing; device and
App Store builds need a development team set on both targets
(`DEVELOPMENT_TEAM` in `project.yml` or Signing in Xcode).

## How the widget stays fresh

The widget **feeds itself**. When WidgetKit asks the extension for a
timeline, `Provider.getTimeline` fetches a batch of articles from the
Wikipedia API and schedules them at the user's refresh interval (default 6
hours), then hands back `policy: .atEnd` — so WidgetKit asks again when the
timeline is spent. The app does not need to run for the widget to update.

Data crosses the app ↔ widget boundary through the App Group
`group.com.temo.wikipedia.newtab` (see `Shared/SharedStore.swift`):

- **Settings** — theme, language, sections, entry length, refresh interval.
  Changing them calls `WidgetCenter.reloadAllTimelines()`.
- **Article cache** — every article that enters a timeline is cached by
  pageId, so a widget tap resolves hours later via
  `wikipedia-newtab://article/<pageId>`.
- **Latest article + stats** — cold start and offline fallback.

iOS budgets widget reloads (roughly 40–70 per day for a frequently viewed
widget); actual refresh timing is always approximate.

## Design

Barbechero tokens (see `docs/design-system.md`): paper `#F7F5EE`, ink
`#211D17` carried by alpha, a single terracotta accent `#9D5035`, Spectral
for text and IBM Plex Mono for labels. `Shared/Palette.swift` holds both
schemes; dark is a derived relationship since the manual is print-only.
