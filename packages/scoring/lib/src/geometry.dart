import 'dart:math' as math;

import 'point.dart';

/// Result of projecting a point onto a polyline.
class Nearest {
  const Nearest(this.distance, this.param);

  /// Euclidean distance to the closest point on the polyline.
  final double distance;

  /// Arc-length position of that closest point, normalized to 0–1.
  final double param;
}

/// A polyline with cached cumulative lengths for fast nearest-point queries.
class PolylineIndex {
  PolylineIndex(List<Pt> pts) : pts = List.unmodifiable(pts) {
    final c = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      c.add(c.last + pts[i - 1].distanceTo(pts[i]));
    }
    cum = List.unmodifiable(c);
    total = c.last;
  }

  final List<Pt> pts;
  late final List<double> cum;
  late final double total;

  /// True when the path ends where it started (circle, closed shape).
  bool get isClosed => pts.length > 2 && pts.first.distanceTo(pts.last) < total * 0.02;

  Nearest nearest(Pt p) {
    if (pts.length == 1) return Nearest(p.distanceTo(pts.first), 0);
    var bestD = double.infinity;
    var bestParam = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final abx = b.x - a.x, aby = b.y - a.y;
      final len2 = abx * abx + aby * aby;
      var t = 0.0;
      if (len2 > 0) {
        t = ((p.x - a.x) * abx + (p.y - a.y) * aby) / len2;
        t = t.clamp(0.0, 1.0);
      }
      final qx = a.x + abx * t, qy = a.y + aby * t;
      final dx = p.x - qx, dy = p.y - qy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < bestD) {
        bestD = d;
        final along = cum[i] + math.sqrt(len2) * t;
        bestParam = total == 0 ? 0 : along / total;
      }
    }
    return Nearest(bestD, bestParam);
  }
}

/// Dynamic time warping distance between two point sequences, normalized by
/// the longer sequence length so it reads as "average matched deviation".
double dtwDistance(List<Pt> a, List<Pt> b) {
  if (a.isEmpty || b.isEmpty) return double.infinity;
  final n = a.length, m = b.length;
  var prev = List<double>.filled(m + 1, double.infinity);
  var cur = List<double>.filled(m + 1, double.infinity);
  prev[0] = 0;
  for (var i = 1; i <= n; i++) {
    cur[0] = double.infinity;
    for (var j = 1; j <= m; j++) {
      final cost = a[i - 1].distanceTo(b[j - 1]);
      final best = math.min(prev[j], math.min(cur[j - 1], prev[j - 1]));
      cur[j] = cost + best;
    }
    final tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[m] / math.max(n, m);
}
