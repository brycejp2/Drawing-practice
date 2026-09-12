import 'package:scoring/scoring.dart';
import 'package:test/test.dart';

void main() {
  test('M and L produce the raw points in order', () {
    final pts = flattenSvgPath('M 150 500 L 850 500');
    expect(pts.length, 2);
    expect(pts.first.x, 150);
    expect(pts.last.x, 850);
  });

  test('implicit lineto after moveto and relative commands', () {
    final pts = flattenSvgPath('M 0 0 10 0 l 0 10 h -10 v -10');
    expect(pts.map((p) => '${p.x},${p.y}').toList(), ['0.0,0.0', '10.0,0.0', '10.0,10.0', '0.0,10.0', '0.0,0.0']);
  });

  test('cubic curves are subdivided and end on the target', () {
    final pts = flattenSvgPath('M 0 0 C 0 100 100 100 100 0', curveSegments: 10);
    expect(pts.length, 11);
    expect(pts.last.x, closeTo(100, 1e-9));
    expect(pts.last.y, closeTo(0, 1e-9));
    // Midpoint of this symmetric curve is at y = 75.
    expect(pts[5].y, closeTo(75, 1e-9));
  });

  test('Z closes back to the subpath start', () {
    final pts = flattenSvgPath('M 0 0 L 10 0 L 10 10 Z');
    expect(pts.last.x, 0);
    expect(pts.last.y, 0);
  });

  test('arcs are rejected with a clear error', () {
    expect(() => flattenSvgPath('M 0 0 A 5 5 0 0 1 10 10'), throwsUnsupportedError);
  });
}
