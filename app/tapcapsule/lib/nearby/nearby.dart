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

  Future<void> start({required String role}) async {
    _role = role;
    emit({'type': 'status', 'value': role == 'sender' ? 'advertising' : 'browsing'});
    _t1 = Timer(const Duration(milliseconds: 500), () {
      emit({'type': 'status', 'value': 'connecting'});
    });
    _t2 = Timer(const Duration(milliseconds: 1000), () {
      emit({'type': 'connected', 'peer': 'Demo iPhone'});
    });

    _t3 = Timer(const Duration(milliseconds: 1700), () {
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
    _t3?.cancel();
    _t3 = Timer(const Duration(milliseconds: 700), () {
      emit({'type': 'payload', 'json': jsonEncode(payload)});
    });
  }

  Future<void> stop() async {
    for (final t in [_t1, _t2, _t3]) {
      t?.cancel();
    }
    emit({'type': 'disconnected'});
  }
}
