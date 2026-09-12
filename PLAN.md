# Drawing Practice — App Plan

A mobile app that teaches drawing, lettering in multiple styles, and pen control
through guided tracing. Every exercise is built from **directed strokes**: the app shows
where to start, which way to go, and in what order. The user traces with a finger or
stylus and gets scored on accuracy, direction, order, and control.

**Decisions so far**
- Primary platform: native mobile apps (iOS and Android). Designed phone-first, then
  adapted up to tablets.
- Audience: beginners to intermediate, middle school age (11+) and older.
- Content: authored in-house. No community packs for now.
- Monetization: free core with a hybrid Pro unlock (yearly subscription or lifetime
  purchase). No ads. Details in section 8.
- Accounts: none in v1. All progress is on-device; purchases are tied to the app store
  account, not to us. Accounts and sync arrive after launch.

---

## 1. Goals and non-goals

**Goals**
- Teach motor skill through a scaffolded progression: trace → faded guide → freehand.
- Cover three content areas with one shared engine: pen exercises, lettering, drawing.
- Give immediate, specific feedback per stroke ("started at the wrong end", "drifted
  right on the curve"), not just a pass/fail.
- Work offline, be genuinely good with a finger on a phone, and feel great with a
  stylus on a tablet.

**Non-goals (for v1)**
- Free-form sketching app with layers, brushes, and export to PSD.
- Social feed, sharing, or user-generated exercise packs.
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
- Zigzags, dot-to-dot, mazes.
- **Mirror and symmetry drills** (see 3.4).

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

### 3.4 Mirror and symmetry drills
Three drill types, used in both the pen and drawing modules:
- **Live mirror**: the user draws one half of a shape (vase, butterfly, face outline)
  and the app mirrors the stroke in real time across a vertical or horizontal axis.
  Builds confidence and makes symmetric forms feel achievable.
- **Complete the half**: the left half of a reference is shown; the user draws the right
  half. Scored by mirroring the user's strokes and comparing to the shown half.
- **Draw the mirror image**: a shape is shown; the user draws its reflection. Trains
  spatial reasoning and reverse-direction strokes.
Axes: vertical, horizontal, and (later) radial for mandalas and snowflakes.

---

## 4. Scoring engine

Pure, tested module with no UI dependencies. Input: reference strokes and user strokes.
Output: a score 0–100 and a list of per-stroke findings.

**Per-stroke metrics**
- **Shape accuracy**: resample both paths to N points, compute mean and max deviation.
  Dynamic Time Warping (DTW) or discrete Fréchet distance handles speed variation.
- **Direction**: user's first point must be near the reference start (not the end); the
  user's progress along the reference must be mostly monotonic.
- **Start/end precision**: distance from reference endpoints; overshoot/undershoot.
- **Smoothness**: jitter measured from second differences of the resampled path.
- **Speed consistency**: variance of velocity.
- **Pressure profile**: correlation with the target profile when pressure is available.

**Per-exercise metrics**
- Stroke count and order match.
- Time taken (informational, not penalized).

**Feedback messages** are generated from the metrics with thresholds, e.g.
"Started at the wrong end", "Wrong direction on stroke 2", "Shaky on the curve",
"Overshot the baseline", "Too fast on the downstroke".

**Tolerance** is per-exercise and per-tier (wide corridor for Trace, tighter for Ghost),
multiplied by a user-level **tolerance multiplier** (see 5.1) and widened automatically
for finger input versus stylus input.

---

## 5. v1 feature set

Everything in this section ships in the first release, alongside the content modules
and scoring engine above.

### 5.1 Feedback and learning
- **Replay overlay**: after an attempt, the user's ink animates on top of the reference
  with off-path segments in red. Scrubbable. Also shows the ghost pen and the user's pen
  side by side for direction mistakes.
- **Live corridor feedback**: ink turns red and a light haptic tick fires when the pen
  leaves the tolerance band. Can be turned off per user.
- **Hint button**: replays the ghost pen for the current stroke only, without resetting
  the attempt.
- **Error heatmap**: for each exercise, the app accumulates where the user's ink deviates
  from the reference across all attempts and renders it as a color overlay on the
  reference shape. Warm colors show habitual trouble spots (e.g. "you always overshoot
  the bowl of the a"). Shown on the exercise detail screen and in the progress view.
  Implementation: bucket per-point deviation along the reference path's arc length (say
  50 buckets per stroke), keep a running mean and count per bucket, render with a
  sequential palette.
- **Tolerance multiplier**: a single slider (Tight / Normal / Relaxed / Very relaxed) in
  settings that scales every corridor. Useful for beginners, small phone screens, and
  users with motor difficulties.
- **Daily warm-up**: a 5-minute routine assembled from the user's weakest recent items
  plus a couple of general control drills. One tap from the home screen.

### 5.2 Guides and canvas
- **Adjustable guides**: baseline, x-height, cap-height, slant angle, square grid, dot
  grid, isometric grid. Saved per style with sensible defaults.
- Zoom and canvas size so an exercise can be practiced small (finger control) or large
  (arm movement, tablets).
- Phone-first layout: the canvas takes the full width in portrait, controls sit in a
  single thumb-reachable bar at the bottom, and the exercise view scrolls horizontally
  for words and sentences rather than shrinking the letters. Tablets get a wider canvas,
  a side panel for guides and replay, and landscape support.
- Paper background options (plain, lined, dotted) mostly for feel.

### 5.3 Input
- Finger is the default input and every exercise must be passable with it on a
  6-inch screen. Stylus is detected automatically and tightens the tolerance.
- Fingertip occlusion: the active stroke's guide is offset or magnified in a small
  inset so the user can see where the path goes under their finger.
- Palm rejection when a stylus is active.
- Pressure and tilt are captured and rendered when the hardware provides them (Apple
  Pencil, S Pen, USI styluses); they are only *scored* in exercises that ask for them.

### 5.4 Modes and accessibility
- **Left-handed mode**: primary controls move to the left edge, slant guides flip, and
  exercises that have a natural left-handed variant (e.g. horizontal strokes) offer it.
- **Kids mode**: tuned for the younger end of the audience (11–14), not small children.
  Larger strokes and targets, a slightly more relaxed default tolerance, shorter
  sessions, feedback phrased as one short tip instead of a metrics list, optional sound
  effects, celebratory animations on tier unlocks, and a simpler home screen. No change
  to the underlying content. A parent or the user can toggle it in settings.
- High-contrast and colorblind-safe palettes for guides, corridor, and heatmap.

### 5.5 Content creation (in-house)
- **Type-to-trace**: the user types a word or sentence, picks an installed style, and
  the app assembles a tracing exercise from the style's glyph strokes with proper
  spacing and joins. This is the main way users get "custom" content without us
  accepting user-authored packs.
- **Internal authoring tool**: a stroke editor (draw, snap, reorder, set direction,
  tag construction vs final, export JSON) used by the content team. Ships in the
  codebase behind a build flag, not in the public app.

---

## 6. Technical architecture

**Recommendation: Flutter, one codebase for iOS and Android.**

Why Flutter over the alternatives for this app:
- Drawing is the whole product. Flutter renders its own canvas, so ink rendering and
  guide animation are identical on both platforms and run at native frame rate.
- Pointer events expose pressure, tilt, orientation, and pointer kind (stylus vs touch)
  on both platforms without native plugins.
- Fast to iterate on custom UI, which this app is mostly made of.

Alternatives considered:
- **React Native + Skia**: viable, similar result, but the stylus input path is less
  mature and needs more native code.
- **Fully native (Swift + PencilKit, Kotlin)**: best possible Pencil latency on iPad,
  at the cost of two codebases and two scoring engines to keep in sync. Revisit only if
  Flutter's stylus latency proves to be a problem in the prototype.

| Layer | Choice | Why |
|---|---|---|
| App | Flutter (Dart) | Single codebase, custom-canvas strengths |
| Ink capture | `Listener` / `PointerEvent` with pressure, tilt, kind | Cross-platform stylus data |
| Ink rendering | `CustomPainter` on a dedicated layer | Fast repaint of only the ink layer |
| Guides and animation | Separate `CustomPainter` + Flutter animations | Ghost pen, fading guide, arrows |
| Smoothing | One-Euro filter on input | Removes jitter without visible lag |
| State | Riverpod | Testable, scales well |
| Storage | SQLite via `drift` | Offline-first attempts, heatmap buckets, progress |
| Content | JSON packs bundled as assets, versioned | In-house content, updated with app releases |
| Scoring | Pure Dart package with unit tests | No UI dependency, easy to test against recorded attempts |
| Haptics / audio | Platform channels via existing plugins | Corridor feedback, kids mode sounds |
| Purchases | StoreKit 2 / Google Play Billing via `in_app_purchase` | Pro entitlement without our own accounts; restore purchases from the store |
| Sync (later) | Firebase or Supabase | Accounts and cross-device progress, after launch |

**No accounts in v1**: all attempts, heatmaps, and progress live in the on-device
database. The Pro entitlement is read from the app store receipt, so a user on a new
phone taps "Restore purchases" and keeps Pro. Progress does not transfer between
devices until accounts arrive after launch; the app should offer a local backup/restore
file (export to Files / share sheet) so a phone upgrade does not wipe progress. No
personal data is collected, which keeps the under-13 part of the audience simple.

**Content format**: JSON packs. Stroke paths are SVG `d` strings in a normalized
1000×1000 box so they render at any size.

```
ExercisePack { id, title, category: pen | letters | drawing, level, exercises[] }
Exercise {
  id, title, instructions,
  guides?: { baseline, xHeight, capHeight, slantDeg },
  strokes: Stroke[]            // ordered
  tolerance: { trace, fade, ghost, freehand }
  symmetry?: { axis: vertical | horizontal, mode: live | complete | reflect }
  tags[]
}
Stroke { id, path, kind: construction | final, pressure?, hint?, leftHandedPath? }
Attempt { exerciseId, tier, startedAt, strokes: UserStroke[], score, findings[] }
UserStroke { points: [{ x, y, t, p?, tiltX?, tiltY? }] }
HeatmapBucket { exerciseId, strokeId, bucketIndex, meanDeviation, count }
```

**Sources of stroke data**
- Hershey fonts (public domain single-stroke vector fonts) for monoline letters.
- Hand-authored SVG for print, cursive, italic, brush, gothic, and all drawing content,
  produced with the internal authoring tool.

**Repo layout** (M0 in place; later directories marked *planned*)
```
app/                     Flutter app
  assets/content/        JSON packs bundled with the app
  lib/content/           pack models and loader
  lib/ink/               pointer capture, One-Euro smoothing, ink painter
  lib/guides/            guide painter, arrows, corridor, ghost-pen animation
  lib/ui/                screens and components
  lib/progress/          planned: drift models, mastery/unlock, heatmap buckets
  lib/authoring/         planned: internal stroke editor (build flag)
  test/                  widget tests (trace a line, wrong direction, multi-stroke)
  tool/                  dev-only preview renderer
packages/scoring/        pure Dart scoring engine + tests
```

---

## 7. Milestones

**M0 — Prototype (2 weeks)** — *code in repo, device testing pending*
Flutter canvas with finger and stylus input, a starter pack of four exercises with
directed strokes, ghost-pen demo and per-stroke hint, corridor display, per-stroke
scoring with findings, results sheet, undo/clear. Remaining M0 work is on devices: run
on a mid-range Android phone, an iPhone, and one tablet with a stylus, then tune
smoothing and tolerance defaults. Goal: confirm finger tracing on a phone feels good and
stylus latency is acceptable before building anything else.

**M1 — Core loop**
Five practice tiers with unlocks, per-stroke feedback, replay overlay, live corridor
feedback, hint button, adjustable guides, tolerance multiplier, local progress. Pen
exercise pack and the print alphabet.

**M2 — Content and modes**
Internal authoring tool, block capitals, cursive, italic, drawing module (shapes → forms
→ perspective → contour), mirror and symmetry drills, type-to-trace, left-handed mode,
kids mode, error heatmap, daily warm-up.

**M3 — Launch**
Remaining styles (monoline, brush, gothic), shading and gesture content, store
listings, onboarding, Pro paywall and purchase flow with restore, local backup/restore,
tablet layout pass, privacy-safe on-device analytics on where users get stuck.

**M4 — After launch**
Accounts and sync (with an age gate and parental consent flow for under-13 users),
family plan, then items from the Later list based on what users ask for.

---

## 8. Monetization

**Decision: free core with a hybrid Pro unlock. No ads.**

Constraints that shaped the choice:
- Part of the audience is under 13, which brings COPPA (US) and similar rules. Targeted
  ads and behavioral tracking are risky and, for a focused practice app, unpleasant.
- Content is produced in-house, so there is a steady stream of new styles and packs
  that can be sold.
- Beginners drop off quickly if the free tier is too thin, and parents buy for the
  younger users, so the value has to be obvious before the paywall.

| Option | How it works | Pros | Cons |
|---|---|---|---|
| **Paid app** (one-time) | Charge up front, everything included | Simple, no paywall friction, parents understand it | Low download volume, no recurring revenue, hard to fund new content |
| **Free + lifetime unlock** | Free core, one purchase unlocks everything | Popular with users who dislike subscriptions, easy to explain | Revenue per user caps out; new content has to be funded from new users |
| **Free + subscription** | Free core, monthly/yearly for all styles, drawing courses, warm-ups, sync | Recurring revenue funds ongoing content, standard for learning apps | Subscription fatigue, harder sell to teens, churn when users feel "done" |
| **Free + style/course packs** | Buy the cursive pack, the perspective course, etc. individually | Matches the in-house content pipeline, pay for what you want | Many small decisions for the user, complex store catalog, lower total spend |
| **Hybrid: subscription or lifetime** | Offer both a subscription and a one-time "lifetime" price | Captures both kinds of buyer, common pattern in this category | Two prices to explain; lifetime price must be set high enough |
| **School and clinic licensing** | Site licenses for schools, tutoring centers, occupational therapists | Sticky, larger contracts, fits the middle-school audience | Slow sales cycle, needs a teacher dashboard and procurement support |
| **Ads** | Free with banner or rewarded ads | Zero-friction free tier | Bad fit for under-13 users, breaks concentration during tracing, low revenue |

**What ships at launch**
- Free: pen exercises, print alphabet, first drawing pack, daily warm-up, all feedback
  features (replay, corridor, hint, heatmap for free content). Enough to get real value
  and form a habit.
- Pro: all lettering styles, full drawing curriculum, mirror and symmetry drills beyond
  the starter set, type-to-trace in every style, and heatmap history across all content.
  Offered as a yearly subscription and a lifetime purchase at roughly 2.5–3× the yearly
  price. A short free trial on the subscription is worth testing.
- Purchases go through StoreKit and Google Play Billing; there is no account on our
  side, so "Restore purchases" is the recovery path.
- Paywall placement: shown when the user opens Pro content or finishes the free print
  alphabet, never mid-exercise.
- Later: family plan once accounts exist; school licensing in the year after launch if
  teachers show up in the user base.

---

## 9. Later (saved for after launch)

**Feedback and learning**
- Side-by-side "before vs now" from first attempt to latest.
- Spaced repetition: poorly scored letters and shapes come back sooner.
- Ghosting: hover-then-commit lines for stylus users who want to rehearse.
- Metronome / tempo mode for consistent speed.
- Non-dominant hand mode with its own progress track.

**Guides and canvas**
- Grid-method copying: a reference photo and the canvas share a grid.
- Radial symmetry for mandalas and snowflakes.

**Content creation**
- Import an SVG or photo, auto-trace to strokes, then fix in the authoring tool.
- Photograph your own handwriting to generate a "your current style" reference.
- Printable PDF worksheets matching the on-screen exercises.
- Outline-tracing mode for any installed outline font.

**Motivation and structure**
- Streaks, XP, badges, mastery tests that gate a level.
- Courses: a linear path (e.g. "Cursive in 30 days") over the exercise library.
- Timed drills and personal bests.

**Audiences**
- Therapist mode with exportable progress reports.
- Teacher dashboard for school licensing.

**More scripts and styles**
- Greek, Cyrillic, Hebrew, Arabic, Devanagari, Japanese kana, Chinese characters
  (open stroke-order datasets make CJK feasible).
- Calligraphy nibs: broad-edge and pointed-pen simulation from tilt or a fixed angle.

**Community**
- Sharing and user-authored exercise packs, if content demand outgrows the in-house
  pipeline.

---

## 10. Risks to watch

- **Finger tracing on small screens** is the whole bet of phone-first. If the M0
  prototype shows that letters at phone scale are too fiddly, the fix is larger default
  canvas scale with horizontal scrolling, not a switch to tablet-first.
- **Lost progress without accounts.** Local backup/restore must be easy to find, and
  the app should nudge users to back up before a major OS upgrade.
- **Content velocity.** Every style is 60+ hand-authored glyphs plus words and joins.
  The authoring tool needs to exist before M2 content work starts.
- **Store review for under-13 audiences.** Even with no accounts, both stores ask
  about the target age group; keep analytics on-device and avoid third-party SDKs that
  collect identifiers.
