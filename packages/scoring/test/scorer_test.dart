import 'dart:math' as math;

import 'package:scoring/scoring.dart';
import 'package:test/test.dart';

const tol = 45.0;
const scorer = StrokeScorer();

final line = flattenSvgPath('M 150 500 L 850 500');
final circle = flattenSvgPath(
  'M 500 200 C 334 200 200 334 200 500 C 200 666 334 800 500 800 '
  'C 666 800 800 666 800 500 C 800 334 666 200 500 200',
);

List<Pt> shifted(List<Pt> pts, double dx, double dy) => pts.map((p) => Pt(p.x + dx, p.y + dy)).toList();

List<Pt> wobbly(List<Pt> pts, double amp, int seed) {
  final rnd = math.Random(seed);
  final dense = resample(pts, 200);
  return dense.map((p) => Pt(p.x + (rnd.nextDouble() * 2 - 1) * amp, p.y + (rnd.nextDouble() * 2 - 1) * amp)).toList();
}

void main() {
  test('a perfect trace scores near 100 with no findings', () {
    final s = scorer.scoreStroke(reference: line, user: line, tolerance: tol);
    expect(s.score, greaterThanOrEqualTo(98));
    expect(s.findings, isEmpty);
  });

  test('a slightly wobbly trace still scores well', () {
    final s = scorer.scoreStroke(reference: line, user: wobbly(line, 6, 1), tolerance: tol);
    expect(s.score, greaterThanOrEqualTo(85));
    expect(s.findings.where((f) => f.kind != FindingKind.shaky), isEmpty);
  });

  test('a reversed stroke is flagged as wrong direction and capped', () {
    final s = scorer.scoreStroke(reference: line, user: line.reversed.toList(), tolerance: tol);
    expect(s.findings.map((f) => f.kind), contains(FindingKind.wrongDirection));
    expect(s.score, lessThanOrEqualTo(25));
  });

  test('a reversed circle is flagged as wrong direction (closed path)', () {
    final s = scorer.scoreStroke(reference: circle, user: circle.reversed.toList(), tolerance: tol);
    expect(s.findings.map((f) => f.kind), contains(FindingKind.wrongDirection));
  });

  test('a correct circle that starts slightly past the start point is fine', () {
    // Rotate the start by a few points: same direction, tiny offset.
    final rotated = [...circle.sublist(3), ...circle.sublist(1, 4)];
    final s = scorer.scoreStroke(reference: circle, user: rotated, tolerance: tol);
    expect(s.findings.map((f) => f.kind), isNot(contains(FindingKind.wrongDirection)));
    expect(s.score, greaterThanOrEqualTo(90));
  });

  test('a stroke offset by twice the tolerance is off path and scores low', () {
    final s = scorer.scoreStroke(reference: line, user: shifted(line, 0, tol * 2), tolerance: tol);
    expect(s.findings.map((f) => f.kind), contains(FindingKind.offPath));
    expect(s.score, lessThan(30));
  });

  test('half a stroke is incomplete', () {
    final half = flattenSvgPath('M 150 500 L 500 500');
    final s = scorer.scoreStroke(reference: line, user: half, tolerance: tol);
    expect(s.findings.map((f) => f.kind), contains(FindingKind.incomplete));
    expect(s.score, lessThan(60));
  });

  test('a tap is too short', () {
    final s = scorer.scoreStroke(reference: line, user: [const Pt(150, 500), const Pt(160, 500)], tolerance: tol);
    expect(s.findings.map((f) => f.kind), contains(FindingKind.tooShort));
    expect(s.score, 0);
  });

  test('exercise scoring reports missing and extra strokes', () {
    final ref = [line, flattenSvgPath('M 500 200 L 500 800')];
    final missing = scorer.scoreExercise(reference: ref, user: [line], tolerance: tol);
    expect(missing.findings.map((f) => f.kind), contains(FindingKind.missingStroke));
    expect(missing.score, closeTo(50, 2));

    final extra = scorer.scoreExercise(reference: ref, user: [...ref, line], tolerance: tol);
    expect(extra.findings.map((f) => f.kind), contains(FindingKind.extraStroke));
    expect(extra.score, lessThan(100));
  });
}
