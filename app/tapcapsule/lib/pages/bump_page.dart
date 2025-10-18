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
    _sub = Nearby.events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'status':
        if (e['value'] == 'connecting') _set(BumpStatus.discovering, 'Connessione…');
        if (e['value'] == 'browsing' || e['value'] == 'advertising') {
            _set(BumpStatus.discovering, _isSender ? 'Waiting for a nearby iPhone…' : 'Looking for a nearby iPhone…');
        }
        break;
      case 'connected':
        _set(BumpStatus.peerFound, 'Connected to ${e['peer']}');
        if (_isSender) _sendSecret();
        break;
      case 'sent':
        _set(BumpStatus.sent, 'Code sent ✔️');
        break;
      case 'payload':
        final map = jsonDecode(e['json'] as String) as Map<String, dynamic>;
        final payload = BumpPayload.fromJson(map);
        AppMemory.lastBumpPayload = payload;
        _set(BumpStatus.received, 'Voucher received ✔️');
        Nearby.stop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text('Voucher received. You can redeem it whenever you want.')),
          );
        }
        break;
      case 'disconnected':
        if (_status == BumpStatus.sent || _status == BumpStatus.received) {
          _set(BumpStatus.idle, 'Session ended');
        } else {
          _set(BumpStatus.error, 'Connection lost');
        }
        break;
      case 'error':
        _set(BumpStatus.error, e['message']?.toString() ?? 'Error');
        break;
    }
  }

  void _set(BumpStatus s, String? m) => setState(() {
    _status = s;
    _msg = m;
  });

  Future<void> _start() async {
    _set(BumpStatus.discovering, _isSender ? 'Waiting for a nearby iPhone…' : 'Looking for a nearby iPhone…');
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
    _set(BumpStatus.sent, 'Code sent ✔️');
  }

  Future<void> _reset() async {
    await Nearby.stop();
    _set(BumpStatus.idle, null);
  }

  @override
  void dispose() {
    _sub.cancel();
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
          title: _isSender ? 'Send nearby' : 'Receive nearby',
          caption: _isSender
              ? 'Keep phones close together. The voucher will be sent automatically when connected.'
              : 'Keep phones close together. The voucher will arrive automatically.',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.radar),
                  label: Text(_isSender ? 'Start sending' : 'Search nearby'),
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
            title: 'Voucher received',
            caption: 'Press when you want to redeem.',
            children: [
              Text(
                '${p.amount} ETH',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Chip(label: Text('Expires: ${p.expiry.toLocal()}')),
              FilledButton.icon(
                icon: const Icon(Icons.download_done_outlined),
                label: const Text('Go to Redeem'),
                onPressed: () {
                  hideAllTextMenusAndKeyboard();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RedeemPage(
                        secretPrefill: p.secret,
                        autoRedeem: false,
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

Widget stepChips(int current) {
  const labels = ['1 Create', '2 Bump', '3 Redeem'];
  return Material(
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
