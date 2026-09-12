/// Categories of feedback the scorer can produce.
enum FindingKind {
  wrongDirection,
  wrongStart,
  incomplete,
  offPath,
  endpoint,
  shaky,
  tooShort,
  missingStroke,
  extraStroke,
}

/// A single piece of feedback tied to a stroke index (0-based).
class Finding {
  const Finding(this.kind, this.strokeIndex, this.message);

  final FindingKind kind;
  final int strokeIndex;
  final String message;

  @override
  String toString() => 'Finding(${kind.name}, stroke ${strokeIndex + 1}: $message)';
}

/// Raw measurements for one stroke, all in normalized content units.
class StrokeMetrics {
  const StrokeMetrics({
    required this.meanDeviation,
    required this.maxDeviation,
    required this.dtw,
    required this.startDistance,
    required this.endDistance,
    required this.startParam,
    required this.netProgress,
    required this.coverage,
    required this.jitter,
    required this.userLength,
    required this.referenceLength,
  });

  final double meanDeviation;
  final double maxDeviation;
  final double dtw;
  final double startDistance;
  final double endDistance;

  /// Where along the reference (0–1) the user's first point landed.
  final double startParam;

  /// Signed fraction of the reference traversed. +1 is a full correct pass,
  /// -1 is a full pass in the wrong direction.
  final double netProgress;

  /// Fraction of the reference the user covered, 0–1.
  final double coverage;

  /// Excess wobble compared with the reference shape (unitless).
  final double jitter;

  final double userLength;
  final double referenceLength;
}

class StrokeScore {
  const StrokeScore({
    required this.strokeIndex,
    required this.score,
    required this.metrics,
    required this.findings,
  });

  final int strokeIndex;

  /// 0–100.
  final double score;
  final StrokeMetrics? metrics;
  final List<Finding> findings;
}

class ExerciseScore {
  const ExerciseScore({required this.score, required this.strokes, required this.findings});

  /// 0–100.
  final double score;
  final List<StrokeScore> strokes;

  /// All findings across strokes plus exercise-level ones (missing/extra).
  final List<Finding> findings;
}
