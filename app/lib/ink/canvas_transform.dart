import 'dart:ui';

/// Maps between the content's normalized 1000×1000 box and widget pixels.
/// The box is scaled to the widget's shortest side and centered.
class CanvasTransform {
  CanvasTransform(Size size)
      : side = size.shortestSide,
        scale = size.shortestSide / 1000,
        origin = Offset((size.width - size.shortestSide) / 2, (size.height - size.shortestSide) / 2);

  static const double normalizedSize = 1000;

  final double side;
  final double scale;
  final Offset origin;

  Offset toNormalized(Offset local) => (local - origin) / scale;
  Offset toLocal(Offset normalized) => normalized * scale + origin;
}
