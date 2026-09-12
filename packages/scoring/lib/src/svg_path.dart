import 'point.dart';

final RegExp _tokenRe = RegExp(
  r'[MmLlHhVvCcSsQqTtZzAa]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

const String _commands = 'MmLlHhVvCcSsQqTtZzAa';

/// Flattens an SVG path `d` string into a polyline.
///
/// Supports M, L, H, V, C, S, Q, T, Z (absolute and relative). Curves are
/// subdivided into [curveSegments] straight segments. Elliptical arcs (A) are
/// not supported; author content with cubic curves instead.
///
/// Point order is the stroke direction.
List<Pt> flattenSvgPath(String d, {int curveSegments = 24}) {
  final tokens = _tokenRe.allMatches(d).map((m) => m.group(0)!).toList();
  final out = <Pt>[];
  var i = 0;
  String? cmd;
  double cx = 0, cy = 0; // current point
  double sx = 0, sy = 0; // subpath start
  double? ccx, ccy; // last cubic control point (for S)
  double? qcx, qcy; // last quadratic control point (for T)

  bool isCmd(String t) => t.length == 1 && _commands.contains(t);

  double number() {
    if (i >= tokens.length || isCmd(tokens[i])) {
      throw FormatException('Expected a number in SVG path "$d"');
    }
    return double.parse(tokens[i++]);
  }

  void emit(double x, double y) {
    cx = x;
    cy = y;
    out.add(Pt(x, y));
  }

  void cubic(double x1, double y1, double x2, double y2, double x, double y) {
    final x0 = cx, y0 = cy;
    for (var k = 1; k <= curveSegments; k++) {
      final t = k / curveSegments;
      final u = 1 - t;
      final px = u * u * u * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x;
      final py = u * u * u * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y;
      emit(px, py);
    }
    ccx = x2;
    ccy = y2;
  }

  void quad(double x1, double y1, double x, double y) {
    final x0 = cx, y0 = cy;
    for (var k = 1; k <= curveSegments; k++) {
      final t = k / curveSegments;
      final u = 1 - t;
      final px = u * u * x0 + 2 * u * t * x1 + t * t * x;
      final py = u * u * y0 + 2 * u * t * y1 + t * t * y;
      emit(px, py);
    }
    qcx = x1;
    qcy = y1;
  }

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd == null) {
      throw FormatException('SVG path must start with a command: "$d"');
    } else if (cmd == 'M') {
      cmd = 'L'; // implicit lineto after moveto
    } else if (cmd == 'm') {
      cmd = 'l';
    }

    final keepCubic = cmd == 'C' || cmd == 'c' || cmd == 'S' || cmd == 's';
    final keepQuad = cmd == 'Q' || cmd == 'q' || cmd == 'T' || cmd == 't';

    switch (cmd) {
      case 'M':
        final x = number(), y = number();
        cx = x;
        cy = y;
        sx = x;
        sy = y;
        out.add(Pt(x, y));
      case 'm':
        final x = cx + number(), y = cy + number();
        cx = x;
        cy = y;
        sx = x;
        sy = y;
        out.add(Pt(x, y));
      case 'L':
        emit(number(), number());
      case 'l':
        emit(cx + number(), cy + number());
      case 'H':
        emit(number(), cy);
      case 'h':
        emit(cx + number(), cy);
      case 'V':
        emit(cx, number());
      case 'v':
        emit(cx, cy + number());
      case 'C':
        cubic(number(), number(), number(), number(), number(), number());
      case 'c':
        final x1 = cx + number(), y1 = cy + number();
        final x2 = cx + number(), y2 = cy + number();
        final x = cx + number(), y = cy + number();
        cubic(x1, y1, x2, y2, x, y);
      case 'S':
        final x1 = ccx == null ? cx : 2 * cx - ccx!;
        final y1 = ccy == null ? cy : 2 * cy - ccy!;
        cubic(x1, y1, number(), number(), number(), number());
      case 's':
        final x1 = ccx == null ? cx : 2 * cx - ccx!;
        final y1 = ccy == null ? cy : 2 * cy - ccy!;
        final x2 = cx + number(), y2 = cy + number();
        final x = cx + number(), y = cy + number();
        cubic(x1, y1, x2, y2, x, y);
      case 'Q':
        quad(number(), number(), number(), number());
      case 'q':
        final x1 = cx + number(), y1 = cy + number();
        final x = cx + number(), y = cy + number();
        quad(x1, y1, x, y);
      case 'T':
        final x1 = qcx == null ? cx : 2 * cx - qcx!;
        final y1 = qcy == null ? cy : 2 * cy - qcy!;
        quad(x1, y1, number(), number());
      case 't':
        final x1 = qcx == null ? cx : 2 * cx - qcx!;
        final y1 = qcy == null ? cy : 2 * cy - qcy!;
        final x = cx + number(), y = cy + number();
        quad(x1, y1, x, y);
      case 'Z':
      case 'z':
        if (out.isNotEmpty && (cx != sx || cy != sy)) emit(sx, sy);
      case 'A':
      case 'a':
        throw UnsupportedError('Elliptical arcs are not supported; use cubic curves.');
      default:
        throw FormatException('Unknown SVG path command "$cmd"');
    }

    if (!keepCubic) {
      ccx = null;
      ccy = null;
    }
    if (!keepQuad) {
      qcx = null;
      qcy = null;
    }
  }
  return out;
}
