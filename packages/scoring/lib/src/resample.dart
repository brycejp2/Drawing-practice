import 'point.dart';

/// Removes consecutive points closer than [eps].
List<Pt> dedupe(List<Pt> pts, {double eps = 1e-6}) {
  if (pts.isEmpty) return const [];
  final out = <Pt>[pts.first];
  for (var i = 1; i < pts.length; i++) {
    if (out.last.distanceTo(pts[i]) > eps) out.add(pts[i]);
  }
  return out;
}

/// Resamples a polyline to exactly [n] points spaced evenly by arc length.
List<Pt> resample(List<Pt> pts, int n) {
  assert(n >= 2, 'resample needs at least 2 points');
  final p = dedupe(pts);
  if (p.isEmpty) return const [];
  final total = polylineLength(p);
  if (p.length == 1 || total == 0) return List<Pt>.filled(n, p.first);

  final step = total / (n - 1);
  final out = <Pt>[p.first];
  var prev = p.first;
  var acc = 0.0;
  var idx = 1;
  while (out.length < n - 1 && idx < p.length) {
    final next = p[idx];
    final segLen = prev.distanceTo(next);
    if (acc + segLen >= step) {
      final f = segLen == 0 ? 1.0 : (step - acc) / segLen;
      final q = prev.lerp(next, f);
      out.add(q);
      prev = q;
      acc = 0;
    } else {
      acc += segLen;
      prev = next;
      idx++;
    }
  }
  while (out.length < n) {
    out.add(p.last);
  }
  return out;
}
