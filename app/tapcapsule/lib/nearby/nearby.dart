import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class Nearby {
  static const _m = MethodChannel('tapcapsule/nearby');
  static const _e = EventChannel('tapcapsule/nearby/events');

  static final StreamController<Map<String, dynamic>> _ctrl = StreamController.broadcast();

  static void ensureListening() {
    _e.receiveBroadcastStream().listen((event) {
      if (event is Map) _ctrl.add(Map<String, dynamic>.from(event));
    });
  }

  static Stream<Map<String, dynamic>> get events {
    ensureListening();
    return _ctrl.stream;
  }

  static Future<void> startSender() => _m.invokeMethod('start', {'role': 'sender'});
  static Future<void> startReceiver() => _m.invokeMethod('start', {'role': 'receiver'});
  static Future<void> stop() => _m.invokeMethod('stop');

  static Future<void> sendJson(Map<String, dynamic> payload) =>
      _m.invokeMethod('sendJson', {'json': jsonEncode(payload)});
}
