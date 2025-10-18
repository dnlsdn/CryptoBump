// lib/pages/bump_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../state/app_memory.dart';
import '../nearby/nearby.dart';
import 'redeem_page.dart';

enum BumpStatus { idle, discovering, peerFound, sent, received, error }

class BumpPage extends StatefulWidget {
  const BumpPage({super.key});
  @override
  State<BumpPage> createState() => _BumpPageState();
}

class _BumpPageState extends State<BumpPage> {
  BumpStatus _status = BumpStatus.idle;
  String? _msg;
  late final bool _isSender;

  @override
  void initState() {
    super.initState();
    _isSender = AppMemory.lastVoucher != null;
    Nearby.events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'status':
        if (e['value'] == 'connecting') _set(BumpStatus.discovering, 'Connessione…');
        if (e['value'] == 'browsing' || e['value'] == 'advertising') {
          _set(BumpStatus.discovering, _isSender ? 'In attesa di un iPhone vicino…' : 'Cerco un iPhone vicino…');
        }
        break;
      case 'connected':
        _set(BumpStatus.peerFound, 'Connesso a ${e['peer']}');
        if (_isSender) _sendSecret(); // auto-send sul sender
        break;
      case 'sent':
        _set(BumpStatus.sent, 'Codice inviato ✔️');
        break;
      case 'payload':
        final map = jsonDecode(e['json'] as String) as Map<String, dynamic>;
        final payload = BumpPayload.fromJson(map);
        AppMemory.lastBumpPayload = payload;
        _set(BumpStatus.received, 'Buono ricevuto ✔️');
        // Apri direttamente Redeem
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RedeemPage()));
        }
        break;
      case 'disconnected':
        _set(BumpStatus.error, 'Connessione persa');
        break;
      case 'error':
        _set(BumpStatus.error, e['message']?.toString() ?? 'Errore');
        break;
    }
  }

  void _set(BumpStatus s, String? m) => setState(() {
    _status = s;
    _msg = m;
  });

  Future<void> _start() async {
    _set(BumpStatus.discovering, _isSender ? 'In attesa di un iPhone vicino…' : 'Cerco iPhone vicino…');
    if (_isSender) {
      await Nearby.startSender();
    } else {
      await Nearby.startReceiver();
    }
  }

  Future<void> _sendSecret() async {
    final v = AppMemory.lastVoucher;
    if (v == null) return;
    final payload = BumpPayload.fromVoucher(v).toJson();
    await Nearby.sendJson(payload);
  }

  Future<void> _reset() async {
    await Nearby.stop();
    _set(BumpStatus.idle, null);
  }

  @override
  void dispose() {
    Nearby.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = AppMemory.lastVoucher;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bump (${_isSender ? "Mittente" : "Destinatario"})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            _isSender
                ? 'Tieni questo iPhone vicino all’altro. Invio automatico del buono quando connessi.'
                : 'Tieni questo iPhone vicino all’altro. Il buono arriverà automaticamente.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.radar),
                label: Text(_isSender ? 'Attiva invio' : 'Cerca vicino'),
                onPressed: _status == BumpStatus.discovering ? null : _start,
              ),
              TextButton.icon(icon: const Icon(Icons.restart_alt), label: const Text('Stop'), onPressed: _reset),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _status == BumpStatus.sent || _status == BumpStatus.received
                    ? Icons.check_circle
                    : _status == BumpStatus.error
                    ? Icons.error_outline
                    : _status == BumpStatus.peerFound
                    ? Icons.link
                    : _status == BumpStatus.discovering
                    ? Icons.hourglass_bottom
                    : Icons.info_outline,
              ),
              title: Text(_status.toString().split('.').last),
              subtitle: _msg != null ? Text(_msg!) : null,
            ),
          ),
          const SizedBox(height: 12),
          if (_isSender && v != null) Text('Ultimo buono: ${v.amount} ETH • h=${v.h.substring(0, 10)}…'),
        ],
      ),
    );
  }
}
