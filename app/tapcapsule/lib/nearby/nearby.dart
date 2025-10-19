import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../state/app_memory.dart';
import '../models/voucher.dart';

class Nearby {
  static const _m = MethodChannel('tapcapsule/nearby');
  static const _e = EventChannel('tapcapsule/nearby/events');

  static final StreamController<Map<String, dynamic>> _ctrl = StreamController.broadcast();
  static bool _listening = false;

  static _MockNearby? _mock;

  static void _emit(Map<String, dynamic> e) => _ctrl.add(e);

  static void ensureListening() {
    if (_listening) return;
    _listening = true;
    if (!AppConfig.I.demoNearby) {
      _e.receiveBroadcastStream().listen((event) {
        if (event is Map) _ctrl.add(Map<String, dynamic>.from(event));
      });
    }
  }

  static Stream<Map<String, dynamic>> get events {
    ensureListening();
    return _ctrl.stream;
  }

  static Future<void> startSender() async {
    if (AppConfig.I.demoNearby) {
      _mock ??= _MockNearby(_emit);
      return _mock!.start(role: 'sender');
    }
    return _m.invokeMethod('start', {'role': 'sender'});
  }

  static Future<void> startReceiver() async {
    if (AppConfig.I.demoNearby) {
      _mock ??= _MockNearby(_emit);
      return _mock!.start(role: 'receiver');
    }
    return _m.invokeMethod('start', {'role': 'receiver'});
  }

  static Future<void> stop() async {
    if (AppConfig.I.demoNearby) {
      await _mock?.stop();
      return;
    }
    return _m.invokeMethod('stop');
  }

  static Future<void> sendJson(Map<String, dynamic> payload) async {
    if (AppConfig.I.demoNearby) {
      _mock ??= _MockNearby(_emit);
      return _mock!.sendJson(payload);
    }
    return _m.invokeMethod('sendJson', {'json': jsonEncode(payload)});
  }
}

class _MockNearby {
  final void Function(Map<String, dynamic>) emit;
  Timer? _t1, _t2, _t3;
  String? _role;

  _MockNearby(this.emit);

  Timer? _t4;

  Future<void> start({required String role}) async {
    _role = role;
    emit({'type': 'status', 'value': role == 'sender' ? 'advertising' : 'browsing'});

    // Searching phase (1.5s)
    _t1 = Timer(const Duration(milliseconds: 1500), () {
      emit({'type': 'status', 'value': 'connecting'});
    });

    // Approaching phase (0.8s after connecting)
    _t2 = Timer(const Duration(milliseconds: 2300), () {
      emit({'type': 'status', 'value': 'approaching'});
    });

    // Connected phase (1s after approaching)
    _t3 = Timer(const Duration(milliseconds: 3300), () {
      emit({'type': 'connected', 'peer': 'Device'});
    });

    // Auto-receive after connection (if receiver)
    _t4 = Timer(const Duration(milliseconds: 5500), () {
      if (_role == 'receiver') {
        final v = AppMemory.lastVoucher;
        if (v != null) {
          final payload = BumpPayload.fromVoucher(v).toJson();
          emit({'type': 'payload', 'json': jsonEncode(payload)});
        }
      }
    });
  }

  Future<void> sendJson(Map<String, dynamic> payload) async {
    emit({'type': 'sent'});
    _t4?.cancel();
    // Give time for transfer animation to play
    _t4 = Timer(const Duration(milliseconds: 1500), () {
      emit({'type': 'payload', 'json': jsonEncode(payload)});
    });
  }

  Future<void> stop() async {
    for (final t in [_t1, _t2, _t3, _t4]) {
      t?.cancel();
    }
    emit({'type': 'disconnected'});
  }
}
