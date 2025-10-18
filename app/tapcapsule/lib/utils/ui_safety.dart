import 'package:flutter/material.dart';

/// Chiude focus/tastiera e qualsiasi menu di sistema aperto (iOS).
void hideAllTextMenusAndKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  ContextMenuController.removeAny();
}
