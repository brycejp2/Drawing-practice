import 'package:flutter/material.dart';

import 'ui/pack_screen.dart';

void main() {
  runApp(const DrawingPracticeApp());
}

class DrawingPracticeApp extends StatelessWidget {
  const DrawingPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Practice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B6FE0),
        scaffoldBackgroundColor: const Color(0xFFF6F7FA),
        useMaterial3: true,
      ),
      home: const PackScreen(),
    );
  }
}
