import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/pack_loader.dart';
import 'exercise_screen.dart';

/// Lists the exercises in the bundled starter pack.
class PackScreen extends StatefulWidget {
  const PackScreen({super.key, this.assetPath = 'assets/content/m0.json'});

  final String assetPath;

  @override
  State<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends State<PackScreen> {
  late final Future<ExercisePack> _pack = loadPack(widget.assetPath);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExercisePack>(
      future: _pack,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Could not load pack: ${snap.error}')));
        }
        final pack = snap.data;
        if (pack == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(title: Text(pack.title)),
          body: ListView.separated(
            itemCount: pack.exercises.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = pack.exercises[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(e.title),
                subtitle: Text('${e.strokes.length} ${e.strokes.length == 1 ? 'stroke' : 'strokes'} · ${e.tags.join(', ')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ExerciseScreen(exercise: e)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
