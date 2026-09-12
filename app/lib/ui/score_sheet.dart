import 'package:flutter/material.dart';
import 'package:scoring/scoring.dart';

/// Results panel shown when every stroke of an exercise has been drawn.
class ScoreSheet extends StatelessWidget {
  const ScoreSheet({super.key, required this.result, required this.onRetry, required this.onDone});

  final ExerciseScore result;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  static String labelFor(double score) {
    if (score >= 90) return 'Excellent control';
    if (score >= 75) return 'Nice work';
    if (score >= 50) return 'Getting there';
    return 'Keep practicing';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              result.score.round().toString(),
              key: const Key('overall-score'),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(labelFor(result.score), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final s in result.strokes) _StrokeRow(score: s),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onDone, child: const Text('Done'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: onRetry, child: const Text('Try again'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokeRow extends StatelessWidget {
  const _StrokeRow({required this.score});

  final StrokeScore score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = score.findings.isEmpty ? 'Clean stroke.' : score.findings.map((f) => f.message).join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text('${score.score.round()}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stroke ${score.strokeIndex + 1}', style: theme.textTheme.labelLarge),
                Text(msg, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
