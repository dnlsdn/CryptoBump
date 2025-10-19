import 'package:flutter/material.dart';

/// Service to show demo hints in web simulator mode
class DemoHintsService {
  static final DemoHintsService _instance = DemoHintsService._internal();
  factory DemoHintsService() => _instance;
  DemoHintsService._internal();

  final ValueNotifier<DemoHint?> currentHint = ValueNotifier(null);

  void show(String message, {DemoHintPosition position = DemoHintPosition.right}) {
    currentHint.value = DemoHint(message: message, position: position);
  }

  void hide() {
    currentHint.value = null;
  }
}

enum DemoHintPosition {
  left,
  right,
  top,
  bottom,
}

class DemoHint {
  final String message;
  final DemoHintPosition position;

  DemoHint({required this.message, required this.position});
}

final demoHints = DemoHintsService();
