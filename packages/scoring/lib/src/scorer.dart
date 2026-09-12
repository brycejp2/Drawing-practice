import 'dart:math' as math;

import 'geometry.dart';
import 'models.dart';
import 'point.dart';
import 'resample.dart';

/// Tunable thresholds. Values are multiples of the exercise tolerance unless
/// noted. Defaults are starting points to tune against recorded attempts.
class ScoringConfig {
  const ScoringConfig({
    this.samples = 64,
    this.tooShortFraction = 0.15,
    this.incompleteCoverage = 0.8,
    this.wrongDirectionProgress = -0.3,
    this.wrongStartFactor = 2.5,
    this.endpointFactor = 2.0,
    this.shakyJitter = 0.3,
  });

  final int samples;
  final double tooShortFraction;
  final double incompleteCoverage;
  final double wrongDirectionProgress;
  final double wrongStartFactor;
  final double endpointFactor;
  final double shakyJitter;
}

/// Scores user strokes against directed reference strokes.
class StrokeScorer {
  const StrokeScorer({this.config = const ScoringConfig()});

  final ScoringConfig config;

  /// Scores one user stroke against one reference stroke.
  ///
  /// [tolerance] is the corridor half-width in normalized units. A mean
  /// deviation within 30% of it scores full marks for shape; at the tolerance
  /// it scores 50; at twice the tolerance, 0.
  StrokeScore scoreStroke({
    required List<Pt> reference,
    required List<Pt> user,
    required double tolerance,
    int strokeIndex = 0,
  }) {
    final n = config.samples;
    final refR = resample(reference, n);
    final userClean = dedupe(user);
    final refLen = polylineLength(refR);
    final userLen = polylineLength(userClean);
    final findings = <Finding>[];

    if (userClean.length < 2 || userLen < refLen * config.tooShortFraction) {
      findings.add(Finding(FindingKind.tooShort, strokeIndex, 'That stroke was too short. Follow the whole path.'));
      return StrokeScore(strokeIndex: strokeIndex, score: 0, metrics: null, findings: findings);
    }

    final userR = resample(userClean, n);
    final index = PolylineIndex(refR);
    final closed = index.isClosed;

    var sumD = 0.0, maxD = 0.0;
    final params = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final near = index.nearest(userR[i]);
      sumD += near.distance;
      if (near.distance > maxD) maxD = near.distance;
      params[i] = near.param;
    }
    final meanD = sumD / n;

    var net = 0.0;
    var minP = params.first, maxP = params.first;
    for (var i = 1; i < n; i++) {
      var d = params[i] - params[i - 1];
      if (closed) {
        if (d > 0.5) d -= 1;
        if (d < -0.5) d += 1;
      }
      net += d;
      minP = math.min(minP, params[i]);
      maxP = math.max(maxP, params[i]);
    }
    final coverage = closed ? math.min(1.0, net.abs()) : (maxP - minP);

    final startDistance = userR.first.distanceTo(refR.first);
    final endDistance = userR.last.distanceTo(refR.last);
    final jitter = _jitter(userR) - _jitter(refR);
    final dtw = dtwDistance(userR, refR);

    final metrics = StrokeMetrics(
      meanDeviation: meanD,
      maxDeviation: maxD,
      dtw: dtw,
      startDistance: startDistance,
      endDistance: endDistance,
      startParam: params.first,
      netProgress: net,
      coverage: coverage,
      jitter: jitter,
      userLength: userLen,
      referenceLength: refLen,
    );

    final wrongDirection = net < config.wrongDirectionProgress;
    final wrongStart = !wrongDirection && startDistance > tolerance * config.wrongStartFactor;
    final incomplete = coverage < config.incompleteCoverage;
    final offPath = meanD > tolerance;
    final endpoint = !wrongDirection && !incomplete && endDistance > tolerance * config.endpointFactor;
    final shaky = jitter > config.shakyJitter;

    if (wrongDirection) {
      findings.add(Finding(FindingKind.wrongDirection, strokeIndex, 'Wrong direction. Start at the green dot and follow the arrows.'));
    }
    if (wrongStart) {
      findings.add(Finding(FindingKind.wrongStart, strokeIndex, 'Started in the wrong place. Begin at the green dot.'));
    }
    if (incomplete) {
      findings.add(Finding(FindingKind.incomplete, strokeIndex, 'Stroke stopped early. Carry it all the way to the red dot.'));
    }
    if (offPath) {
      findings.add(Finding(FindingKind.offPath, strokeIndex, 'Drifted off the path. Slow down and stay inside the band.'));
    }
    if (endpoint) {
      findings.add(Finding(FindingKind.endpoint, strokeIndex, 'Overshot or stopped short of the end point.'));
    }
    if (shaky) {
      findings.add(Finding(FindingKind.shaky, strokeIndex, 'A little shaky. Try one smooth, confident motion.'));
    }

    var score = _shapeScore(meanD / tolerance) * 100;
    if (incomplete) score *= coverage;
    if (wrongDirection) score = math.min(score, 25);
    if (wrongStart) score -= 15;
    if (endpoint) score -= 10;
    if (shaky) score -= 10;
    score = score.clamp(0, 100);

    return StrokeScore(
      strokeIndex: strokeIndex,
      score: (score * 10).roundToDouble() / 10,
      metrics: metrics,
      findings: findings,
    );
  }

  /// Scores a whole exercise. Stroke i of the user is compared with stroke i
  /// of the reference; order is enforced by the caller's UI.
  ExerciseScore scoreExercise({
    required List<List<Pt>> reference,
    required List<List<Pt>> user,
    required double tolerance,
  }) {
    final strokes = <StrokeScore>[];
    final findings = <Finding>[];
    for (var i = 0; i < reference.length; i++) {
      if (i < user.length) {
        final s = scoreStroke(reference: reference[i], user: user[i], tolerance: tolerance, strokeIndex: i);
        strokes.add(s);
        findings.addAll(s.findings);
      } else {
        final f = Finding(FindingKind.missingStroke, i, 'Stroke ${i + 1} is missing.');
        findings.add(f);
        strokes.add(StrokeScore(strokeIndex: i, score: 0, metrics: null, findings: [f]));
      }
    }
    var extraPenalty = 0.0;
    for (var i = reference.length; i < user.length; i++) {
      findings.add(Finding(FindingKind.extraStroke, i, 'Extra stroke ${i + 1} is not part of this shape.'));
      extraPenalty += 5;
    }
    final mean = strokes.isEmpty ? 0.0 : strokes.map((s) => s.score).reduce((a, b) => a + b) / strokes.length;
    final total = (mean - extraPenalty).clamp(0.0, 100.0);
    return ExerciseScore(score: (total * 10).roundToDouble() / 10, strokes: strokes, findings: findings);
  }

  /// Piecewise-linear map from normalized deviation to 0–1 shape quality:
  /// (0,1) (0.3,1) (1,0.5) (2,0).
  static double _shapeScore(double r) {
    if (r <= 0.3) return 1;
    if (r <= 1) return 1 - 0.5 * (r - 0.3) / 0.7;
    if (r <= 2) return 0.5 * (2 - r);
    return 0;
  }

  /// Mean second-difference magnitude relative to spacing. Evenly resampled
  /// straight lines give ~0; curvature contributes a baseline, which callers
  /// subtract by measuring the reference too.
  static double _jitter(List<Pt> r) {
    if (r.length < 3) return 0;
    final spacing = polylineLength(r) / (r.length - 1);
    if (spacing == 0) return 0;
    var sum = 0.0;
    for (var i = 1; i < r.length - 1; i++) {
      final ax = r[i + 1].x - 2 * r[i].x + r[i - 1].x;
      final ay = r[i + 1].y - 2 * r[i].y + r[i - 1].y;
      sum += math.sqrt(ax * ax + ay * ay);
    }
    return sum / (r.length - 2) / spacing;
  }
}
