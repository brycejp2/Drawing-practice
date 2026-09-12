import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Loads a bundled JSON exercise pack from assets.
Future<ExercisePack> loadPack(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  return ExercisePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
