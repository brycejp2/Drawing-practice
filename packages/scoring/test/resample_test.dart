import 'package:scoring/scoring.dart';
import 'package:test/test.dart';

void main() {
  test('resample returns exactly n evenly spaced points', () {
    final pts = [const Pt(0, 0), const Pt(100, 0), const Pt(100, 100)];
    final r = resample(pts, 21);
    expect(r.length, 21);
    for (var i = 1; i < r.length; i++) {
      expect(r[i - 1].distanceTo(r[i]), closeTo(10, 1e-6));
    }
    expect(r.last.x, 100);
    expect(r.last.y, 100);
  });

  test('degenerate input is handled', () {
    expect(resample(const [], 8), isEmpty);
    expect(resample([const Pt(3, 3)], 8).length, 8);
    expect(resample([const Pt(3, 3), const Pt(3, 3)], 8).length, 8);
  });
}
