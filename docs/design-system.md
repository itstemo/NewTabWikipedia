# Design tokens

Extracted from the Barbechero Manual de Diseño. The system is a printed-label
aesthetic: warm paper, near-black warm ink, a single accent, hairline rules,
no shadows, no border radius.

## Color

| Token | Value | Use |
| --- | --- | --- |
| `paper` | `#F7F5EE` | Page/surface background |
| `paper-deep` | `#EFEAE0` | Hover/filled states ("papel hondo") — never use color for hover |
| `paper-edge` | `#E6DFD0` | Inset panels, swatch borders |
| `ink` | `#211D17` | Text, major rules |
| `ink-75` | `rgba(33,29,23,.75)` | Emphasized secondary text |
| `ink-62` | `rgba(33,29,23,.62)` | Secondary text |
| `ink-55` | `rgba(33,29,23,.55)` | Field labels, kickers |
| `ink-45` | `rgba(33,29,23,.45)` | Captions, placeholders |
| `ink-30` | `rgba(33,29,23,.30)` | Minor rules, link underlines at rest |
| `ink-20` | `rgba(33,29,23,.20)` | Hairline borders on paper-deep |
| `accent` | `oklch(0.52 0.11 40)` ≈ `#9D5035` | The single accent ("tinta viva") |

Accent rules from the manual: one accent per view — links, the active element,
the single piece of data the view exists to show. Never in running text,
never in rules, never below 14 px on screen. On the accent, print paper,
never ink. Dark mode is not in the manual; derive it by keeping the same hue
relationships (deep warm ground, paper-colored text, accent slightly
lightened to keep ≥4.5:1 on the ground).

## Type

| Face | Weights | Use |
| --- | --- | --- |
| Spectral | 300 light, 400 regular, italic, 600 (screen only) | Headlines (300/600), body (400), descriptors and botanical-style terms (italic) |
| IBM Plex Mono | 400, 500 | All field labels, codes, figures, kickers — always uppercase, letter-spacing .16–.22 em |

Both are SIL Open Font License and should be bundled, never loaded from a
CDN: a new tab must not wait on the network, and the iOS app should ship
them in the bundle.

- Chrome extension: drop subsetted `.woff2` files in
  `apps/chrome-extension/fonts/` and register with `@font-face`
  (`font-display: block`).
- iOS: the TTFs live in `apps/ios/Resources/Fonts/` and are registered via
  `UIAppFonts` in `project.yml` (generated Info.plist); the widget target
  inherits them from the shared bundle.

## Shape

- Hairline rules only (1 px / 0.2–0.4 mm equivalent), full ink for major
  rules, `ink-20`–`ink-30` for minor ones.
- No shadows, no border radius, no entrance animation on text.
- Hover and selected states are `paper-deep`, not accent.
