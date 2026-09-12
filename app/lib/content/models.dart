import 'package:scoring/scoring.dart';

class ExercisePack {
  const ExercisePack({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.exercises,
  });

  factory ExercisePack.fromJson(Map<String, dynamic> j) => ExercisePack(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        level: (j['level'] as num?)?.toInt() ?? 1,
        exercises: (j['exercises'] as List).cast<Map<String, dynamic>>().map(Exercise.fromJson).toList(),
      );

  final String id;
  final String title;
  final String category;
  final int level;
  final List<Exercise> exercises;
}

class Exercise {
  Exercise({
    required this.id,
    required this.title,
    required this.instructions,
    required this.strokes,
    required this.tolerance,
    this.guides,
    this.tags = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as String,
        title: j['title'] as String,
        instructions: j['instructions'] as String? ?? '',
        guides: j['guides'] == null ? null : Guides.fromJson(j['guides'] as Map<String, dynamic>),
        strokes: (j['strokes'] as List).cast<Map<String, dynamic>>().map(StrokeSpec.fromJson).toList(),
        tolerance: ToleranceSpec.fromJson(j['tolerance'] as Map<String, dynamic>),
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      );

  final String id;
  final String title;
  final String instructions;
  final Guides? guides;
  final List<StrokeSpec> strokes;
  final ToleranceSpec tolerance;
  final List<String> tags;

  /// Reference polylines in normalized 1000×1000 units, flattened once.
  late final List<List<Pt>> polylines = strokes.map((s) => flattenSvgPath(s.path)).toList();
}

class StrokeSpec {
  const StrokeSpec({required this.id, required this.path, this.kind = 'final', this.hint});

  factory StrokeSpec.fromJson(Map<String, dynamic> j) => StrokeSpec(
        id: j['id'] as String,
        path: j['path'] as String,
        kind: j['kind'] as String? ?? 'final',
        hint: j['hint'] as String?,
      );

  final String id;

  /// SVG path data. Point order is the stroke direction.
  final String path;

  /// "construction" strokes are drawn light and scored loosely; "final" tight.
  final String kind;
  final String? hint;
}

class Guides {
  const Guides({this.baseline, this.xHeight, this.capHeight, this.slantDeg});

  factory Guides.fromJson(Map<String, dynamic> j) => Guides(
        baseline: (j['baseline'] as num?)?.toDouble(),
        xHeight: (j['xHeight'] as num?)?.toDouble(),
        capHeight: (j['capHeight'] as num?)?.toDouble(),
        slantDeg: (j['slantDeg'] as num?)?.toDouble(),
      );

  final double? baseline;
  final double? xHeight;
  final double? capHeight;
  final double? slantDeg;
}

/// Corridor half-widths per practice tier, in normalized units.
class ToleranceSpec {
  const ToleranceSpec({required this.trace, required this.fade, required this.ghost, required this.freehand});

  factory ToleranceSpec.fromJson(Map<String, dynamic> j) => ToleranceSpec(
        trace: (j['trace'] as num).toDouble(),
        fade: (j['fade'] as num).toDouble(),
        ghost: (j['ghost'] as num).toDouble(),
        freehand: (j['freehand'] as num).toDouble(),
      );

  final double trace;
  final double fade;
  final double ghost;
  final double freehand;
}
