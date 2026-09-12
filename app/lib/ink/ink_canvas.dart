import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scoring/scoring.dart';

import 'canvas_transform.dart';
import 'ink_painter.dart';
import 'one_euro_filter.dart';
import 'user_stroke.dart';

/// Captures finger and stylus input, smooths it, and paints ink over a
/// [background] painter (the guides). Emits a [UserStroke] on pointer up.
class InkCanvas extends StatefulWidget {
  const InkCanvas({
    super.key,
    required this.strokes,
    required this.background,
    required this.onStrokeEnd,
    this.enabled = true,
  });

  final List<UserStroke> strokes;
  final CustomPainter background;
  final ValueChanged<UserStroke> onStrokeEnd;
  final bool enabled;

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> {
  final ValueNotifier<UserStroke?> _draft = ValueNotifier<UserStroke?>(null);
  final _fx = OneEuroFilter();
  final _fy = OneEuroFilter();
  final List<Pt> _points = <Pt>[];
  int? _activePointer;
  PointerDeviceKind? _activeKind;
  Size _size = Size.zero;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  bool _isStylus(PointerDeviceKind k) => k == PointerDeviceKind.stylus || k == PointerDeviceKind.invertedStylus;

  void _down(PointerDownEvent e) {
    if (!widget.enabled) return;
    if (_activePointer != null) {
      // Palm rejection: a stylus takes over from a stray touch; anything else
      // while a stroke is in progress is ignored.
      if (_isStylus(e.kind) && !_isStylus(_activeKind!)) {
        _cancel();
      } else {
        return;
      }
    }
    _activePointer = e.pointer;
    _activeKind = e.kind;
    _fx.reset();
    _fy.reset();
    _points.clear();
    _add(e.localPosition, e.timeStamp, e.pressure, raw: true);
    _publish();
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _activePointer) return;
    _add(e.localPosition, e.timeStamp, e.pressure);
    _publish();
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _activePointer) return;
    // Append the raw release position so filter lag never shortens the end.
    _add(e.localPosition, e.timeStamp, e.pressure, raw: true);
    final stroke = UserStroke(points: List.unmodifiable(_points), kind: _activeKind!);
    _clearActive();
    widget.onStrokeEnd(stroke);
  }

  void _cancel() {
    _clearActive();
  }

  void _clearActive() {
    _activePointer = null;
    _activeKind = null;
    _points.clear();
    _draft.value = null;
  }

  void _add(Offset local, Duration ts, double pressure, {bool raw = false}) {
    final n = CanvasTransform(_size).toNormalized(local);
    final t = ts.inMicroseconds / 1e6;
    final x = raw ? n.dx : _fx.filter(n.dx, t);
    final y = raw ? n.dy : _fy.filter(n.dy, t);
    if (raw) {
      // Keep the filters in sync with the raw sample.
      _fx.filter(n.dx, t);
      _fy.filter(n.dy, t);
    }
    final pt = Pt(x, y, t: t, p: pressure);
    if (_points.isNotEmpty && _points.last.distanceTo(pt) < 0.5) return;
    _points.add(pt);
  }

  void _publish() {
    _draft.value = UserStroke(points: List.of(_points), kind: _activeKind!);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: (_) => _cancel(),
          child: CustomPaint(
            painter: widget.background,
            foregroundPainter: InkPainter(strokes: widget.strokes, draft: _draft),
            size: _size,
          ),
        );
      },
    );
  }
}
