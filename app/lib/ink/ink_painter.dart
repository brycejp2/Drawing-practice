import 'package:flutter/material.dart';

import 'canvas_transform.dart';
import 'user_stroke.dart';

/// Paints committed strokes plus the in-progress stroke held in [draft].
class InkPainter extends CustomPainter {
  InkPainter({required this.strokes, required this.draft, this.color = const Color(0xFF1F2430), this.baseWidth = 11})
      : super(repaint: draft);

  final List<UserStroke> strokes;
  final ValueNotifier<UserStroke?> draft;
  final Color color;

  /// Stroke width in normalized units.
  final double baseWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final tf = CanvasTransform(size);
    canvas.save();
    canvas.translate(tf.origin.dx, tf.origin.dy);
    canvas.scale(tf.scale);
    for (final s in strokes) {
      _paintStroke(canvas, s);
    }
    final d = draft.value;
    if (d != null) _paintStroke(canvas, d);
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, UserStroke s) {
    final pts = s.points;
    if (pts.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = baseWidth;

    if (pts.length == 1) {
      canvas.drawCircle(Offset(pts.first.x, pts.first.y), baseWidth / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final usePressure = s.isStylus && pts.any((p) => p.p != null && p.p != 1.0);
    if (!usePressure) {
      final path = Path()..moveTo(pts.first.x, pts.first.y);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].x, pts[i].y);
      }
      canvas.drawPath(path, paint);
      return;
    }

    for (var i = 1; i < pts.length; i++) {
      final p = ((pts[i].p ?? 0.5) + (pts[i - 1].p ?? 0.5)) / 2;
      paint.strokeWidth = baseWidth * (0.4 + 1.2 * p.clamp(0.0, 1.0));
      canvas.drawLine(Offset(pts[i - 1].x, pts[i - 1].y), Offset(pts[i].x, pts[i].y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant InkPainter old) => old.strokes != strokes || old.draft != draft || old.color != color;
}
