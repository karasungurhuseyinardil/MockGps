# Design system

One token set for mobile, site and admin. Sources of truth:
`web/packages/ui/src/tokens.css` and `mobile/lib/core/theme/tokens.dart` (same values).

## Principles

* The map is the hero on mobile. Controls float above it on glass panels.
* Calm neutrals, one brand accent, one semantic colour for **simulated** location.
  Blue = real/brand, coral = simulated — the user always knows which one they are looking at.
* Few, soft animations (150–400 ms). Respect `prefers-reduced-motion` / platform reduce-motion.
* Every view has loading (skeleton), empty, success (toast) and error (retry) states.
* No ads, no promotional popups.

## Colour tokens

| Token | Light | Dark |
|---|---|---|
| `bg` | `#F4F6F9` | `#07090D` |
| `bg-elevated` | `#FFFFFF` | `#0F131A` |
| `surface-glass` | `rgba(255,255,255,0.72)` | `rgba(20,24,32,0.68)` |
| `border` | `rgba(15,23,42,0.08)` | `rgba(255,255,255,0.08)` |
| `text` | `#0B1220` | `#E8ECF2` |
| `text-muted` | `#5B6474` | `#8E97A8` |
| `primary` | `#3457F5` | `#7088FF` |
| `primary-fg` | `#FFFFFF` | `#0A0F1F` |
| `simulated` | `#F2542D` | `#FF7A5C` |
| `success` | `#16A34A` | `#34D399` |
| `warning` | `#D97706` | `#FBBF24` |
| `danger` | `#DC2626` | `#F87171` |

## Shape, space, type, motion

* Radius: `sm 10`, `md 14`, `lg 20`, `xl 28`, `pill 999`.
* Spacing: 4 px scale (4, 8, 12, 16, 20, 24, 32, 40, 48, 64).
* Type: **Inter** (UI), **JetBrains Mono** (coordinates). Scale 12 / 14 / 16 / 18 / 22 / 28 / 36 / 48 / 64.
* Glass: `backdrop-filter: blur(20px) saturate(160%)`, 1 px `border`, shadow `0 8px 32px rgba(0,0,0,.12)`.
* Motion: `fast 150ms`, `base 250ms`, `slow 400ms`, easing `cubic-bezier(0.2, 0.8, 0.2, 1)`.

## Signature element

While a simulation runs, the map pin shows a pulsing coral ring, a fixed status pill sits at the top
("Simulating · 52.5200, 13.4050"), and Android shows a persistent notification with *Stop*.

## Accessibility

* Text contrast ≥ 4.5:1 (AA) in both themes; glass panels keep an opaque-enough background.
* Visible focus rings (`2px primary`, offset 2 px).
* Touch targets ≥ 44×44.
* All icons that act as buttons have labels.
