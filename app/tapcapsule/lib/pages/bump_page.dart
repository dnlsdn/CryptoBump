// lib/pages/bump_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tapcapsule/utils/ui_safety.dart';
import 'package:tapcapsule/widgets/section_card.dart';
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
  late final StreamSubscription<Map<String, dynamic>> _sub;
  bool _navigated = false; // evita push doppi

  @override
  void initState() {
    super.initState();
    _isSender = AppMemory.lastVoucher != null;
    _sub = Nearby.events.listen(_onEvent); // ⬅️ salva subscription
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
        if (mounted && !_navigated) {
          _navigated = true;
          hideAllTextMenusAndKeyboard(); // ⬅️ chiudi eventuali menu iOS
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => RedeemPage(secretPrefill: payload.secret, autoRedeem: true)))
              .then((_) => _navigated = false);
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
    await Nearby.stop(); // <— blocca subito advertising/browsing
    _set(BumpStatus.sent, 'Codice inviato ✔️');
  }

  Future<void> _reset() async {
    await Nearby.stop();
    _set(BumpStatus.idle, null);
  }

  @override
  void dispose() {
    _sub.cancel(); // ⬅️ evita listener duplicati
    Nearby.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = AppMemory.lastVoucher;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        stepChips(1),
        const SizedBox(height: 12),

        SectionCard(
          title: _isSender ? 'Invia vicino' : 'Ricevi vicino',
          caption: _isSender
              ? 'Tieni i telefoni vicini. Il buono viene inviato automaticamente quando connessi.'
              : 'Tieni i telefoni vicini. Il buono arriverà automaticamente.',
          children: [
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
          ],
        ),

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
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(_status.toString().split('.').last, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: _msg != null ? Text(_msg!) : null,
          ),
        ),

        if (_isSender && v != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(label: Text('Buono: ${v.amount} ETH • h=${v.shortH}')),
          ),
      ],
    );
  }
}

// in qualunque file UI:
Widget stepChips(int current) {
  const labels = ['1 Crea', '2 Bump', '3 Incassa'];
  return Wrap(
    spacing: 8,
    children: [
      for (int i = 0; i < labels.length; i++)
        ChoiceChip(label: Text(labels[i]), selected: current == i, showCheckmark: false, onSelected: (_) {}),
    ],
  );
}
