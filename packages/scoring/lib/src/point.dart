import 'dart:math' as math;

/// A 2D point with optional timestamp (seconds) and pressure (0–1).
class Pt {
  const Pt(this.x, this.y, {this.t = 0, this.p});

  final double x;
  final double y;
  final double t;
  final double? p;

  double distanceTo(Pt o) {
    final dx = x - o.x;
    final dy = y - o.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Pt lerp(Pt o, double f) {
    final pa = p;
    final pb = o.p;
    final double? pp;
    if (pa == null || pb == null) {
      pp = pa ?? pb;
    } else {
      pp = pa + (pb - pa) * f;
    }
    return Pt(x + (o.x - x) * f, y + (o.y - y) * f, t: t + (o.t - t) * f, p: pp);
  }

  Pt operator -(Pt o) => Pt(x - o.x, y - o.y);

  @override
  String toString() => 'Pt($x, $y)';
}

/// Total arc length of a polyline.
double polylineLength(List<Pt> pts) {
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += pts[i - 1].distanceTo(pts[i]);
  }
  return total;
}
