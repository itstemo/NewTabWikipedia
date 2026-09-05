# Wikipedia New Tab

A small monorepo for two ways to discover a random Wikipedia article:

- A Chrome MV3 extension that replaces every new tab with an encyclopedia entry.
- An Expo mobile app with an iOS Home Screen widget.

## Repository layout

```text
apps/chrome-extension/   Chrome new-tab extension
apps/mobile/              Expo iOS app and widget
packages/wikipedia/       Shared article types, API request, and filters
```

## Chrome extension

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Choose **Load unpacked**.
4. Select `apps/chrome-extension`.

The extension is deliberately dependency-free and uses a local queue so a new
Tab can paint before the network responds. Its settings panel keeps curated
Wikipedia sections visible, supports searchable custom categories and multiple
selections, and keeps local counters for articles encountered and full entries
opened.

## Mobile development

From the repository root:

```bash
npm install
npm run typecheck
npm test
```

Run the Expo development server:

```bash
cd apps/mobile
npm start
```

The widget is a native iOS extension and is not available in Expo Go. Use an
Expo development build or a prebuild-generated Xcode project:

```bash
cd apps/mobile
npx expo prebuild
npx expo run:ios
```

## TestFlight

After an Apple Developer account and App Store Connect app record exist:

```bash
cd apps/mobile
npx eas-cli login
eas build --platform ios --profile production
eas submit --platform ios
```

The `production` profile uploads a signed iOS build to App Store Connect, where
it can be added to an internal TestFlight group. External testers require
Apple's TestFlight beta review.

## Notes

- Wikipedia requests are made directly from the clients; no server or API key
  is required.
- The app saves the latest article locally, prefers image-backed entries, and
  schedules a small batch of articles for the widget timeline.
- iOS controls the exact timing of background widget refreshes.
