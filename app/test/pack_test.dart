import 'dart:convert';
import 'dart:io';

import 'package:drawing_practice/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled starter pack parses and every stroke flattens', () {
    final raw = File('assets/content/m0.json').readAsStringSync();
    final pack = ExercisePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(pack.exercises, isNotEmpty);
    for (final e in pack.exercises) {
      expect(e.strokes, isNotEmpty, reason: e.id);
      for (final poly in e.polylines) {
        expect(poly.length, greaterThanOrEqualTo(2), reason: e.id);
        for (final p in poly) {
          expect(p.x, inInclusiveRange(0, 1000), reason: e.id);
          expect(p.y, inInclusiveRange(0, 1000), reason: e.id);
        }
      }
    }
  });
}
