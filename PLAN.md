# Drawing Practice — App Plan

An app that teaches drawing, lettering in multiple styles, and pen control through
guided tracing. Every exercise is built from **directed strokes**: the app shows where
to start, which way to go, and in what order. The user traces with a finger or stylus
and gets scored on accuracy, direction, order, and control.

---

## 1. Goals and non-goals

**Goals**
- Teach motor skill through a scaffolded progression: trace → faded guide → freehand.
- Cover three content areas with one shared engine: pen exercises, lettering, drawing.
- Give immediate, specific feedback per stroke ("started at the wrong end", "drifted
  right on the curve"), not just a pass/fail.
- Work offline, on a tablet with a stylus first, but also on phones and desktops.

**Non-goals (for v1)**
- Free-form sketching app with layers, brushes, and export to PSD.
- Social feed. Sharing exercise packs can come later.
- Handwriting recognition (OCR). We compare against a known reference, which is a much
  easier and more useful problem.

---

## 2. Core concept: directed strokes

A directed stroke is an ordered polyline/curve. Direction is implied by point order.
This one primitive powers everything:

| Content area | What a "stroke set" is |
|---|---|
| Pen exercises | Lines, ovals, loops, spirals, hatching, pressure ramps |
| Letters | The stroke order of a glyph in a given style (print, cursive, italic, gothic, brush) |
| Drawing | Construction lines of a subject (circle → head, box → building), then contour lines |

**How direction is shown to the user**
- A numbered green dot at the start of each stroke, red dot at the end.
- An arrowhead mid-stroke and at the end.
- An animated "ghost pen" that travels the path before the user tries (replayable).
- Dashed guide path that fills in solid as the user traces it correctly.
- Strokes are revealed one at a time in order (optional: show all, dimmed).

**Practice tiers (scaffolding)**
1. **Watch** — animated demo of the full stroke set.
2. **Trace** — full guide path visible, tolerance corridor shown.
3. **Fade** — guide fades out as you progress along it; only start dots stay.
4. **Ghost** — only numbered start dots and a faint shape hint.
5. **Freehand** — blank canvas, small reference image in the corner. Scored against the
   reference after best-fit alignment (translation/scale), so you are judged on shape,
   not placement.

Passing a tier (e.g. 80% three times) unlocks the next one for that exercise.

---

## 3. Content modules

### 3.1 Pen exercises (warm-ups and control drills)
- Straight lines: horizontal, vertical, diagonal, between two dots, parallel sets.
- Curves: arcs, C and S curves, waves, ovals, circles (clockwise and counter-clockwise).
- Loops and cursive prep: e-loops, l-loops, figure-8s, connected garlands.
- Spirals: inward and outward.
- Hatching and cross-hatching with even spacing.
- Pressure ramps: light-to-heavy along one line (needs a pressure-capable stylus; falls
  back to speed-based scoring without one).
- Ghosting: hover-then-commit lines (tracked via pointer hover on stylus devices).
- Tempo drills: draw at a set speed with a metronome (consistency of speed is scored).
- Zigzags, dot-to-dot, mazes.

### 3.2 Lettering
Each *style* is a separate stroke-data set for A–Z, a–z, 0–9, and punctuation.

Launch styles, in rough priority order:
1. Print (ball-and-stick, the school standard)
2. Block capitals
3. Cursive (a standard continuous style)
4. Italic / chancery
5. Monoline sans (Hershey-style single-stroke)
6. Brush lettering (thick down, thin up — uses pressure or speed as a proxy)
7. Gothic / blackletter
8. Numbers and punctuation for each style

Progression inside a style: single letters → letter families (e.g. c, o, a, d, g share
the same starting oval) → letter pairs and joins (cursive) → words → sentences with
baseline/x-height guides → free writing.

Guides: baseline, x-height, cap-height, ascender/descender, slant lines (adjustable
angle), letter spacing boxes.

### 3.3 Drawing
1. Basic shapes: circle, square, triangle, ellipse at various tilts.
2. 3D forms: cube, cylinder, cone, sphere with construction lines shown first.
3. Perspective: 1-point and 2-point boxes, then simple buildings.
4. Contour drawing of simple objects (mug, apple, leaf, hand).
5. Construction-based subjects: Loomis head, simple animals from circles/ovals.
6. Shading: value scales, hatching gradients, form shading on a sphere.
7. Gesture drawing: quick timed strokes over a figure reference.

Each drawing exercise separates **construction strokes** (drawn light, scored loosely)
from **final line strokes** (scored tightly).

---

## 4. Scoring engine

Pure, tested TypeScript module. Input: reference strokes and user strokes. Output: a
score 0–100 and a list of per-stroke findings.

**Per-stroke metrics**
- **Shape accuracy**: resample both paths to N points, compute mean and max deviation.
  Dynamic Time Warping (DTW) or discrete Fréchet distance handles speed variation.
- **Direction**: user's first point must be near the reference start (not the end); the
  user's progress along the reference must be mostly monotonic.
- **Start/end precision**: distance from reference endpoints; overshoot/undershoot.
- **Smoothness**: jitter measured from second differences of the resampled path.
- **Speed consistency**: variance of velocity (used for tempo drills).
- **Pressure profile**: correlation with the target profile when pressure is available.

**Per-exercise metrics**
- Stroke count and order match.
- Time taken (informational, not penalized except in timed drills).

**Feedback messages** are generated from the metrics with thresholds, e.g.
"Started at the wrong end", "Wrong direction on stroke 2", "Shaky on the curve",
"Overshot the baseline", "Too fast on the downstroke".

**Tolerance** is per-exercise and per-tier (wide corridor for Trace, tighter for Ghost),
with a global accessibility multiplier the user can set.

---

## 5. Technical architecture

**Recommendation: web-first PWA, wrapped for app stores later.**
Pointer Events give pressure, tilt, and pointer type on iPad (Apple Pencil), Android,
Surface, and Wacom, and one codebase covers all of them. If latency on iPad ever becomes
the limiting factor, the ink layer can be swapped for PencilKit inside a Capacitor shell
without changing the content or scoring modules.

| Layer | Choice | Why |
|---|---|---|
| UI | React + TypeScript + Vite | Fast iteration, big ecosystem |
| Ink capture | Pointer Events + `getCoalescedEvents()` | Full-rate input, pressure, tilt, palm rejection via `pointerType` |
| Ink rendering | Canvas 2D (user ink) over SVG (guides) | Canvas is fast for ink; SVG makes guides, arrows, and animation trivial |
| Stroke look | `perfect-freehand` | Pressure-sensitive, good-looking strokes cheaply |
| Smoothing | One-Euro filter on input | Removes jitter without lag |
| State | Zustand | Small, simple |
| Storage | IndexedDB via Dexie | Offline-first progress and attempts |
| Sync (later) | Supabase or similar | Accounts and cross-device progress |
| Tests | Vitest | Scoring engine needs solid unit tests |
| PWA | vite-plugin-pwa | Installable, offline |

**Content format**: JSON packs. Stroke paths are SVG `d` strings in a normalized
1000×1000 box so they render at any size.

```ts
type ExercisePack = { id; title; category: "pen" | "letters" | "drawing"; level; exercises: Exercise[] };
type Exercise = {
  id; title; instructions;
  guides?: { baseline?; xHeight?; capHeight?; slantDeg? };
  strokes: Stroke[];          // ordered
  tolerance: { trace; fade; ghost; freehand };
  tags: string[];
};
type Stroke = {
  id; path: string;           // SVG path, direction = path order
  kind: "construction" | "final";
  pressure?: "light" | "heavy" | "ramp-up" | "ramp-down";
  hint?: string;
};
type Attempt = { exerciseId; tier; startedAt; strokes: UserStroke[]; score; findings: Finding[] };
type UserStroke = { points: { x; y; t; p?; tx?; ty? }[] };
```

**Sources of stroke data**
- Hershey fonts (public domain single-stroke vector fonts) for monoline letters.
- Hand-authored SVG for print, cursive, italic, brush, gothic. Build a small
  **in-app authoring tool** (draw a stroke, snap, reorder, set direction, export JSON)
  so content can be produced quickly and by non-developers.
- KanjiVG / Make Me a Hanzi for CJK stroke order if those scripts are added.
- Outline fonts (TTF/OTF) cannot give stroke order, but can power an "outline tracing"
  mode for any font the user picks.

**Proposed repo layout**
```
src/
  ink/        pointer capture, smoothing, canvas renderer
  guides/     SVG guide rendering, arrows, ghost-pen animation
  scoring/    pure functions + tests
  content/    JSON packs, loaders, schema validation
  authoring/  stroke editor
  progress/   Dexie models, mastery/unlock logic
  ui/         screens and components
```

---

## 6. Milestones

**M0 — Prototype (1–2 weeks)**
Canvas with stylus input, one exercise with directed strokes and ghost-pen demo, basic
shape+direction score. Goal: confirm the tracing feels good on an iPad.

**M1 — MVP**
Pen exercise pack, print alphabet, five practice tiers with unlocks, per-stroke feedback,
local progress, PWA install, left-handed mode, guide overlays.

**M2 — Content and authoring**
Authoring tool, cursive and italic styles, drawing module (shapes → forms → perspective),
replay of your attempt vs reference, daily warm-up routine, PDF worksheet export.

**M3 — Depth**
Accounts and sync, gamification, spaced repetition on weak items, more scripts,
custom exercises from imported SVG or typed text, community packs.

---

## 7. Other features worth adding

Grouped by how much they change the product. See the end of this section for a
recommended cut for v1.

**Feedback and learning**
- Replay overlay: your attempt animated on top of the reference, with off-path segments
  in red.
- Heatmap of your errors on a letter across many attempts (shows the habitual mistake).
- Side-by-side "before vs now" from your first attempt to your latest.
- Live corridor feedback: ink turns red and a subtle haptic/audio tick when you leave the
  tolerance band.
- Hint button that plays the ghost pen for just the current stroke.
- Spaced repetition: letters and shapes you score poorly on come back sooner.

**Input and hardware**
- Pressure and tilt training with a live pressure meter (stylus devices).
- Stylus-only mode with palm rejection; finger mode with a larger tolerance.
- Hover "ghosting" for stylus users who want to rehearse a line before committing.
- Metronome / tempo mode for consistent speed.
- Non-dominant hand mode (separate progress track; good for rehabilitation).

**Guides and canvas**
- Adjustable guide lines: baseline, x-height, slant, grid, dot grid, isometric grid.
- Paper types and zoom so an exercise can be practiced small (finger control) or large
  (arm movement).
- Mirror-drawing and symmetry exercises (draw one half, app mirrors the other).
- Grid-method copying: reference image and your canvas share a grid.

**Content creation**
- Type any text in any installed style → instant tracing exercise.
- Import an SVG or photo, auto-trace to strokes, then fix in the authoring tool.
- Photograph your own handwriting to generate a "your current style" reference and
  compare it to the target style.
- Printable PDF worksheets that match the on-screen exercises.

**Motivation and structure**
- Daily 5-minute warm-up routine assembled from your weak areas.
- Streaks, XP, badges, and "mastery tests" that gate a level.
- Courses: a linear path (e.g. "Cursive in 30 days") over the exercise library.
- Timed drills and personal bests.

**Accessibility and audiences**
- Tolerance multiplier and larger targets for motor-impairment or occupational-therapy
  use; a "therapist mode" with exportable progress reports.
- Kid mode: bigger strokes, sound effects, simpler UI, no text-heavy feedback.
- Left-handed mode: UI controls on the left, slant guides flipped, some stroke
  directions offered in a left-handed variant.
- High-contrast and colorblind-safe guide colors.

**More scripts and styles**
- Greek, Cyrillic, Hebrew, Arabic, Devanagari, Japanese kana, Chinese characters
  (existing open stroke-order datasets make CJK feasible).
- Calligraphy nibs: broad-edge and pointed-pen simulation (nib angle rendered from
  tilt or a fixed angle).

**Recommended for v1**: replay overlay, live corridor feedback, hint button, adjustable
guides, left-handed mode, daily warm-up, tolerance multiplier, and type-to-trace using
the styles already in the app. These are cheap given the core engine and make the
tracing loop feel complete. Everything else can follow once real users show where the
demand is.

---

## 8. Open questions

- **Platform**: is iPad + Apple Pencil the primary target, or is phone/finger tracing
  equally important? This shifts tolerance defaults and UI density.
- **Audience**: adults learning lettering, kids learning handwriting, or therapy use?
  Each wants different defaults and tone.
- **Monetization**: free with paid style packs, or subscription for courses and sync?
- **Content ownership**: hand-author all styles in-house, or accept community packs
  from day one?
