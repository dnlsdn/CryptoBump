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

        // chiudi la sessione *dopo* aver ricevuto
        Nearby.stop();

        // feedback non invadente
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text('Buono ricevuto. Puoi incassare quando vuoi.')),
          );
        }
        break;
      case 'disconnected':
        if (_status == BumpStatus.sent || _status == BumpStatus.received) {
          _set(BumpStatus.idle, 'Sessione terminata'); // chiusura ok
        } else {
          _set(BumpStatus.error, 'Connessione persa');
        }
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
    // niente stop qui ✅ lascia arrivare l'eco 'payload'
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
    final p = AppMemory.lastBumpPayload;
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

        if (_status == BumpStatus.received && p != null)
          SectionCard(
            title: 'Buono ricevuto',
            caption: 'Premi quando vuoi per incassare.',
            children: [
              Text(
                '${p.amount} ETH',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Chip(label: Text('Scade: ${p.expiry.toLocal()}')),
              FilledButton.icon(
                icon: const Icon(Icons.download_done_outlined),
                label: const Text('Vai a Redeem'),
                onPressed: () {
                  hideAllTextMenusAndKeyboard();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RedeemPage(
                        secretPrefill: p.secret,
                        autoRedeem: false, // ⬅️ niente auto-redeem
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}

// in qualunque file UI:
// in qualunque file UI:
Widget stepChips(int current) {
  const labels = ['1 Crea', '2 Bump', '3 Incassa'];
  return Material(
    // <-- fornisce l’antenato Material richiesto dai ChoiceChip
    type: MaterialType.transparency,
    child: Wrap(
      spacing: 8,
      children: [
        for (int i = 0; i < labels.length; i++)
          ChoiceChip(label: Text(labels[i]), selected: current == i, showCheckmark: false, onSelected: (_) {}),
      ],
    ),
  );
}
