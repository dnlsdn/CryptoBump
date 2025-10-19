import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapcapsule/utils/ui_safety.dart';
import 'package:tapcapsule/widgets/section_card.dart';
import 'package:tapcapsule/widgets/bump_animation.dart';
import '../models/voucher.dart';
import '../state/app_memory.dart';
import '../nearby/nearby.dart';
import '../ui/theme.dart';
import '../config/app_config.dart';
import 'redeem_page.dart';

enum BumpStatus { idle, discovering, approaching, peerFound, sent, received, error }

class BumpPage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const BumpPage({super.key, this.onNavigateToTab});
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
        if (e['value'] == 'connecting') _set(BumpStatus.discovering, 'Searching…');
        if (e['value'] == 'browsing' || e['value'] == 'advertising') {
            _set(BumpStatus.discovering, _isSender ? 'Waiting for nearby device…' : 'Searching for device…');
        }
        if (e['value'] == 'approaching') {
            _set(BumpStatus.approaching, 'Device found!');
        }
        break;
      case 'connected':
        _set(BumpStatus.peerFound, 'Connected');
        // Give animation time to show connection before sending
        if (_isSender) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) _sendSecret();
          });
        }
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

        if (mounted && !kIsWeb) {
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

  BumpAnimationState _getBumpAnimationState() {
    switch (_status) {
      case BumpStatus.idle:
        return BumpAnimationState.idle;
      case BumpStatus.discovering:
        return BumpAnimationState.searching;
      case BumpStatus.approaching:
        return BumpAnimationState.approaching;
      case BumpStatus.peerFound:
        return BumpAnimationState.connected;
      case BumpStatus.sent:
        return BumpAnimationState.transferring;
      case BumpStatus.received:
        return BumpAnimationState.complete;
      case BumpStatus.error:
        return BumpAnimationState.idle;
    }
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
              ? 'Keep devices close together. The voucher will be sent automatically when connected.'
              : 'Keep devices close together. The voucher will arrive automatically.',
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

        // Show animation in demo mode, otherwise show simple status card
        if (AppConfig.I.demoNearby && _status != BumpStatus.idle)
          SectionCard(
            highlight: true,
            children: [
              BumpAnimation(
                state: _getBumpAnimationState(),
                isSender: _isSender,
              ),
            ],
          )
        else
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
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Redeem Now'),
                onPressed: () {
                  hideAllTextMenusAndKeyboard();
                  // Store the secret for the Redeem page to pick up
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(2); // Navigate to Redeem tab (index 2)
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}

Widget stepChips(int current) {
  const labels = ['Create', 'Bump', 'Redeem'];
  const icons = [Icons.receipt_long, Icons.swap_horiz, Icons.account_balance_wallet];

  return Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      for (int i = 0; i < labels.length; i++)
        _StepChip(
          label: labels[i],
          icon: icons[i],
          isActive: current == i,
        ),
    ],
  );
}

class _StepChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const _StepChip({
    required this.label,
    required this.icon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              )
            : null,
        color: isActive ? null : AppTheme.darkCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive
                ? Colors.white
                : AppTheme.lightText.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Colors.white
                  : AppTheme.lightText.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
