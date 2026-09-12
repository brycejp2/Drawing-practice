import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:scoring/scoring.dart';

import '../content/models.dart';
import '../ink/canvas_transform.dart';

/// Position of the animated ghost pen: which stroke and how far along (0–1).
class GhostState {
  const GhostState(this.strokeIndex, this.t);

  final int strokeIndex;
  final double t;
}

class GuideColors {
  static const primary = Color(0xFF3B6FE0);
  static const start = Color(0xFF2FA36B);
  static const end = Color(0xFFD9534F);
  static const upcoming = Color(0xFFD5DAE3);
  static const done = Color(0xFFA9C0F2);
  static const guideLine = Color(0xFFE3E7EF);
  static const ghost = Color(0xFFF2A93B);
}

/// Draws letter guides, the reference strokes with direction cues, the
/// tolerance corridor for the current stroke, and the ghost pen.
class GuidePainter extends CustomPainter {
  GuidePainter({
    required this.exercise,
    required this.currentStroke,
    required this.tolerance,
    this.ghost,
    this.showCorridor = true,
  });

  final Exercise exercise;

  /// Index of the stroke the user should draw next. Strokes before it are
  /// complete; strokes after it are upcoming.
  final int currentStroke;
  final double tolerance;
  final GhostState? ghost;
  final bool showCorridor;

  @override
  void paint(Canvas canvas, Size size) {
    final tf = CanvasTransform(size);
    canvas.save();
    canvas.translate(tf.origin.dx, tf.origin.dy);
    canvas.scale(tf.scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 1000, 1000));

    _paintGuides(canvas);

    final paths = exercise.polylines.map(_toPath).toList();
    for (var i = 0; i < paths.length; i++) {
      if (i < currentStroke) {
        _strokePath(canvas, paths[i], GuideColors.done, 9);
      } else if (i > currentStroke) {
        _strokePath(canvas, paths[i], GuideColors.upcoming, 7);
      }
    }
    if (currentStroke < paths.length) {
      _paintCurrent(canvas, paths[currentStroke], exercise.polylines[currentStroke], currentStroke);
    }
    final g = ghost;
    if (g != null && g.strokeIndex < paths.length) {
      _paintGhost(canvas, paths[g.strokeIndex], g.t);
    }
    canvas.restore();
  }

  void _paintGuides(Canvas canvas) {
    final g = exercise.guides;
    if (g == null) return;
    final paint = Paint()
      ..color = GuideColors.guideLine
      ..strokeWidth = 3;
    for (final y in [g.baseline, g.xHeight, g.capHeight]) {
      if (y != null) canvas.drawLine(Offset(0, y), Offset(1000, y), paint);
    }
  }

  void _paintCurrent(Canvas canvas, Path path, List<Pt> pts, int index) {
    if (showCorridor) {
      _strokePath(canvas, path, GuideColors.primary.withValues(alpha: 0.12), tolerance * 2);
    }
    _dashedPath(canvas, path, GuideColors.primary, 6, dash: 20, gap: 14);

    final closed = pts.length > 2 && pts.first.distanceTo(pts.last) < 20;
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final total = metrics.fold<double>(0, (a, m) => a + m.length);
      _arrowAt(canvas, metrics, total * 0.5);
      // On a closed path the start dot would cover an arrow at the very end.
      _arrowAt(canvas, metrics, closed ? total * 0.9 : total);
    }

    if (!closed) {
      canvas.drawCircle(Offset(pts.last.x, pts.last.y), 11, Paint()..color = GuideColors.end);
    }
    final start = Offset(pts.first.x, pts.first.y);
    canvas.drawCircle(start, 20, Paint()..color = GuideColors.start);
    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, start - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintGhost(Canvas canvas, Path path, double t) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remaining = total * t.clamp(0.0, 1.0);
    final traced = Path();
    Offset? pen;
    for (final m in metrics) {
      if (remaining <= 0) break;
      final take = math.min(remaining, m.length);
      traced.addPath(m.extractPath(0, take), Offset.zero);
      pen = m.getTangentForOffset(take)?.position;
      remaining -= take;
    }
    _strokePath(canvas, traced, GuideColors.ghost, 10);
    if (pen != null) {
      canvas.drawCircle(pen, 16, Paint()..color = GuideColors.ghost.withValues(alpha: 0.35));
      canvas.drawCircle(pen, 8, Paint()..color = GuideColors.ghost);
    }
  }

  void _arrowAt(Canvas canvas, List<PathMetric> metrics, double distance) {
    var d = distance;
    for (final m in metrics) {
      if (d <= m.length) {
        final tangent = m.getTangentForOffset(math.max(0, d - 0.01));
        if (tangent == null) return;
        _arrowHead(canvas, tangent.position, tangent.vector);
        return;
      }
      d -= m.length;
    }
  }

  void _arrowHead(Canvas canvas, Offset tip, Offset dir) {
    if (dir.distance == 0) return;
    final v = dir / dir.distance;
    final n = Offset(-v.dy, v.dx);
    const len = 26.0;
    const half = 14.0;
    final base = tip - v * len;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + n.dx * half, base.dy + n.dy * half)
      ..lineTo(base.dx - n.dx * half, base.dy - n.dy * half)
      ..close();
    canvas.drawPath(path, Paint()..color = GuideColors.primary);
  }

  static Path _toPath(List<Pt> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.x, pts.first.y);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    return path;
  }

  static void _strokePath(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width,
    );
  }

  static void _dashedPath(Canvas canvas, Path path, Color color, double width, {required double dash, required double gap}) {
    final out = Path();
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        final end = math.min(d + dash, m.length);
        out.addPath(m.extractPath(d, end), Offset.zero);
        d += dash + gap;
      }
    }
    _strokePath(canvas, out, color, width);
  }

  @override
  bool shouldRepaint(covariant GuidePainter old) =>
      old.exercise != exercise ||
      old.currentStroke != currentStroke ||
      old.tolerance != tolerance ||
      old.showCorridor != showCorridor ||
      old.ghost?.strokeIndex != ghost?.strokeIndex ||
      old.ghost?.t != ghost?.t;
}
