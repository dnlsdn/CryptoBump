import 'package:flutter/material.dart';

void hideAllTextMenusAndKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  ContextMenuController.removeAny();
}
