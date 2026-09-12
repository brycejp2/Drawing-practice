// Renders the exercise canvas to PNG files for visual review.
// Run: flutter test tool/preview_test.dart
// Output: build/preview/*.png
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_practice/content/models.dart';
import 'package:drawing_practice/guides/guide_painter.dart';
import 'package:drawing_practice/ink/ink_painter.dart';
import 'package:drawing_practice/ink/user_stroke.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoring/scoring.dart';

Future<void> render(String name, Exercise e, {int current = 0, List<UserStroke> strokes = const [], GhostState? ghost}) async {
  const size = Size(600, 600);
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  GuidePainter(exercise: e, currentStroke: current, tolerance: e.tolerance.trace, ghost: ghost).paint(canvas, size);
  InkPainter(strokes: strokes, draft: ValueNotifier(null)).paint(canvas, size);
  final img = await rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File('build/preview/$name.png')..createSync(recursive: true);
  f.writeAsBytesSync(bytes!.buffer.asUint8List());
}

UserStroke wobble(List<Pt> ref, double amp) {
  final r = resample(ref, 80);
  var s = 1.0;
  return UserStroke(
    kind: PointerDeviceKind.touch,
    points: [for (final p in r) Pt(p.x + (s = -s) * amp * (p.x % 7) / 7, p.y + s * amp * (p.y % 5) / 5, p: 1)],
  );
}

void main() {
  testWidgets('render previews', (tester) async {
    final raw = File('assets/content/m0.json').readAsStringSync();
    final pack = ExercisePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final byId = {for (final e in pack.exercises) e.id: e};
    await tester.runAsync(() async {
      final a = byId['print-A']!;
      await render('a_stroke1', a);
      await render('a_stroke3_with_ink', a, current: 2, strokes: [wobble(a.polylines[0], 6), wobble(a.polylines[1], 6)]);
      await render('a_ghost', a, current: 1, strokes: [wobble(a.polylines[0], 6)], ghost: const GhostState(1, 0.6));
      await render('circle', byId['circle-ccw']!);
      await render('wave_ghost', byId['wave']!, ghost: const GhostState(0, 0.45));
    });
  });
}
