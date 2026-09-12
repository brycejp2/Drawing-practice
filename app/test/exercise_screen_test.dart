import 'package:drawing_practice/content/models.dart';
import 'package:drawing_practice/ink/canvas_transform.dart';
import 'package:drawing_practice/ink/ink_canvas.dart';
import 'package:drawing_practice/ui/exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise lineExercise() => Exercise(
      id: 'line-h',
      title: 'Horizontal line',
      instructions: 'Left to right.',
      strokes: const [StrokeSpec(id: 's1', path: 'M 150 500 L 850 500')],
      tolerance: const ToleranceSpec(trace: 45, fade: 35, ghost: 30, freehand: 60),
    );

Exercise letterA() => Exercise(
      id: 'print-A',
      title: 'Capital A',
      instructions: 'Three strokes.',
      strokes: const [
        StrokeSpec(id: 's1', path: 'M 500 180 L 260 820'),
        StrokeSpec(id: 's2', path: 'M 500 180 L 740 820'),
        StrokeSpec(id: 's3', path: 'M 350 580 L 650 580'),
      ],
      tolerance: const ToleranceSpec(trace: 40, fade: 32, ghost: 28, freehand: 55),
    );

/// Drags a finger along the straight line from [from] to [to] in normalized
/// content coordinates.
Future<void> trace(WidgetTester tester, Offset from, Offset to, {int steps = 24}) async {
  final rect = tester.getRect(find.byType(InkCanvas));
  final tf = CanvasTransform(rect.size);
  Offset global(Offset n) => rect.topLeft + tf.toLocal(n);
  final gesture = await tester.startGesture(global(from));
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(global(Offset.lerp(from, to, i / steps)!));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> pumpScreen(WidgetTester tester, Exercise e) async {
  await tester.pumpWidget(MaterialApp(home: ExerciseScreen(exercise: e)));
  // Let the intro ghost-pen animation finish so the canvas is stable.
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  testWidgets('tracing a line correctly shows a high score', (tester) async {
    await pumpScreen(tester, lineExercise());
    expect(find.text('Stroke 1 of 1'), findsOneWidget);

    await trace(tester, const Offset(150, 500), const Offset(850, 500));

    final scoreText = tester.widget<Text>(find.byKey(const Key('overall-score'))).data!;
    expect(int.parse(scoreText), greaterThanOrEqualTo(85));
    expect(find.text('Clean stroke.'), findsOneWidget);
  });

  testWidgets('tracing in the wrong direction is called out', (tester) async {
    await pumpScreen(tester, lineExercise());

    await trace(tester, const Offset(850, 500), const Offset(150, 500));

    final scoreText = tester.widget<Text>(find.byKey(const Key('overall-score'))).data!;
    expect(int.parse(scoreText), lessThanOrEqualTo(25));
    expect(find.textContaining('Wrong direction'), findsWidgets);
  });

  testWidgets('multi-stroke exercise advances stroke by stroke and supports undo', (tester) async {
    await pumpScreen(tester, letterA());
    expect(find.text('Stroke 1 of 3'), findsOneWidget);

    await trace(tester, const Offset(500, 180), const Offset(260, 820));
    expect(find.text('Stroke 2 of 3'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Stroke 1 of 3'), findsOneWidget);

    await trace(tester, const Offset(500, 180), const Offset(260, 820));
    await trace(tester, const Offset(500, 180), const Offset(740, 820));
    expect(find.text('Stroke 3 of 3'), findsOneWidget);

    await trace(tester, const Offset(350, 580), const Offset(650, 580));
    expect(find.byKey(const Key('overall-score')), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Stroke 1 of 3'), findsOneWidget);
  });
}
