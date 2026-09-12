import 'package:flutter/gestures.dart';
import 'package:scoring/scoring.dart';

/// One stroke drawn by the user, in normalized content units.
class UserStroke {
  const UserStroke({required this.points, required this.kind});

  final List<Pt> points;
  final PointerDeviceKind kind;

  bool get isStylus => kind == PointerDeviceKind.stylus || kind == PointerDeviceKind.invertedStylus;
}
