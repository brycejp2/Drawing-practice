import 'package:flutter/material.dart';
import 'package:scoring/scoring.dart';

import '../content/models.dart';
import '../guides/guide_painter.dart';
import '../ink/ink_canvas.dart';
import '../ink/user_stroke.dart';
import 'score_sheet.dart';

/// Trace-tier practice screen: one exercise, strokes drawn in order, each
/// scored on release, results sheet after the last stroke.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with SingleTickerProviderStateMixin {
  static const _scorer = StrokeScorer();

  /// Ghost pen speed in normalized units per second.
  static const _ghostSpeed = 700.0;

  final List<UserStroke> _strokes = [];
  final List<StrokeScore> _strokeScores = [];
  ExerciseScore? _result;
  String? _feedback;
  late final AnimationController _ghost;

  Exercise get _exercise => widget.exercise;
  int get _current => _strokes.length;
  bool get _complete => _current >= _exercise.strokes.length;
  double get _tolerance => _exercise.tolerance.trace;

  @override
  void initState() {
    super.initState();
    _ghost = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: _exercise.strokes.length.toDouble(),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playGhost(0, _exercise.strokes.length);
    });
  }

  @override
  void dispose() {
    _ghost.dispose();
    super.dispose();
  }

  Duration _durationFor(int from, int to) {
    var length = 0.0;
    for (var i = from; i < to; i++) {
      length += polylineLength(_exercise.polylines[i]);
    }
    final ms = (length / _ghostSpeed * 1000).round() + 350 * (to - from);
    return Duration(milliseconds: ms);
  }

  void _playGhost(int from, int to) {
    if (to <= from) return;
    _ghost.stop();
    _ghost.value = from.toDouble();
    _ghost.animateTo(to.toDouble(), duration: _durationFor(from, to), curve: Curves.easeInOut);
  }

  GhostState? _ghostState() {
    if (!_ghost.isAnimating) return null;
    final v = _ghost.value;
    final idx = v.floor().clamp(0, _exercise.strokes.length - 1);
    return GhostState(idx, v - idx);
  }

  void _onStrokeEnd(UserStroke stroke) {
    if (_complete) return;
    final index = _current;
    final score = _scorer.scoreStroke(
      reference: _exercise.polylines[index],
      user: stroke.points,
      tolerance: _tolerance,
      strokeIndex: index,
    );
    setState(() {
      _strokes.add(stroke);
      _strokeScores.add(score);
      _feedback = score.findings.isEmpty ? 'Stroke ${index + 1}: ${score.score.round()}. Clean.' : score.findings.first.message;
      if (_complete) {
        _result = _scorer.scoreExercise(
          reference: _exercise.polylines,
          user: _strokes.map((s) => s.points).toList(),
          tolerance: _tolerance,
        );
      }
    });
    if (_complete) _showResults();
  }

  void _showResults() {
    final result = _result;
    if (result == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ScoreSheet(
        result: result,
        onRetry: () {
          Navigator.of(ctx).pop();
          _reset();
        },
        onDone: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  void _reset() {
    setState(() {
      _strokes.clear();
      _strokeScores.clear();
      _result = null;
      _feedback = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _strokeScores.removeLast();
      _result = null;
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strokeCount = _exercise.strokes.length;
    final hint = _complete ? null : _exercise.strokes[_current].hint;

    return Scaffold(
      appBar: AppBar(title: Text(_exercise.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: const Text('Trace'), visualDensity: VisualDensity.compact),
                      const SizedBox(width: 8),
                      Text(
                        _complete ? 'All $strokeCount strokes done' : 'Stroke ${_current + 1} of $strokeCount',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(hint ?? _exercise.instructions, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE3E7EF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedBuilder(
                      animation: _ghost,
                      builder: (context, _) => InkCanvas(
                        strokes: _strokes,
                        enabled: !_complete,
                        onStrokeEnd: _onStrokeEnd,
                        background: GuidePainter(
                          exercise: _exercise,
                          currentStroke: _current,
                          tolerance: _tolerance,
                          ghost: _ghostState(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  _feedback ?? 'Draw stroke ${_complete ? strokeCount : _current + 1} on the canvas.',
                  key: const Key('feedback'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BarButton(icon: Icons.play_arrow_rounded, label: 'Watch', onPressed: () => _playGhost(0, strokeCount)),
                  _BarButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Hint',
                    onPressed: _complete ? null : () => _playGhost(_current, _current + 1),
                  ),
                  _BarButton(icon: Icons.undo_rounded, label: 'Undo', onPressed: _strokes.isEmpty ? null : _undo),
                  _BarButton(icon: Icons.refresh_rounded, label: 'Clear', onPressed: _strokes.isEmpty ? null : _reset),
                  _BarButton(
                    icon: Icons.assessment_outlined,
                    label: 'Results',
                    onPressed: _result == null ? null : _showResults,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12))],
        ),
      ),
    );
  }
}
