/// Pure Dart stroke-scoring engine.
///
/// Compares a user's traced strokes against directed reference strokes and
/// produces a 0–100 score plus per-stroke findings. All coordinates are in the
/// content's normalized 1000×1000 box, so tolerances are device independent.
library;

export 'src/point.dart';
export 'src/svg_path.dart';
export 'src/resample.dart';
export 'src/geometry.dart' show PolylineIndex, Nearest, dtwDistance;
export 'src/models.dart';
export 'src/scorer.dart';
