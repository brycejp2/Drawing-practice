# Drawing Practice

A mobile app that teaches drawing, lettering, and pen control by tracing directed
strokes. See [PLAN.md](PLAN.md) for the product plan and architecture.

## Layout

| Path | What it is |
|---|---|
| `app/` | Flutter app (iOS and Android) |
| `app/assets/content/` | JSON exercise packs bundled with the app |
| `packages/scoring/` | Pure Dart scoring engine, no Flutter dependency |

## Getting started

Requires the Flutter SDK (3.35 or newer).

```sh
# Scoring engine tests
cd packages/scoring && dart pub get && dart test

# App: analyze, test, run on a connected device
cd app && flutter pub get
flutter analyze
flutter test
flutter run
```

## Content format

Each pack is a JSON file with exercises made of ordered strokes. A stroke's `path` is
SVG path data in a 1000×1000 box; the point order is the direction the user should
draw. Supported commands: M, L, H, V, C, S, Q, T, Z (absolute and relative). Arcs are
not supported; use cubic curves.

```json
{
  "id": "print-A",
  "title": "Capital A (print)",
  "instructions": "Three strokes: down-left, down-right, then the crossbar.",
  "guides": { "baseline": 820, "capHeight": 180 },
  "strokes": [
    { "id": "s1", "path": "M 500 180 L 260 820", "kind": "final", "hint": "Start at the top." }
  ],
  "tolerance": { "trace": 40, "fade": 32, "ghost": 28, "freehand": 55 },
  "tags": ["letters", "print"]
}
```

## Previewing the canvas without a device

`app/tool/preview_test.dart` renders the guide and ink layers to PNGs:

```sh
cd app && flutter test tool/preview_test.dart && ls build/preview
```
