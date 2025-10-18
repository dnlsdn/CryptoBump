import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../state/app_memory.dart';

enum BumpStatus { idle, discovering, peerFound, sent, error }

class BumpPage extends StatefulWidget {
  const BumpPage({super.key});
  @override
  State<BumpPage> createState() => _BumpPageState();
}

class _BumpPageState extends State<BumpPage> {
  BumpStatus _status = BumpStatus.idle;
  String? _msg;

  Future<void> _startDiscover() async {
    setState(() {
      _status = BumpStatus.discovering;
      _msg = 'Cerco iPhone vicino...';
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _status = BumpStatus.peerFound;
      _msg = 'Dispositivo vicino trovato.';
    });
  }

  Future<void> _sendSecret() async {
    final v = AppMemory.lastVoucher;
    if (v == null) {
      setState(() {
        _status = BumpStatus.error;
        _msg = 'Nessun buono da inviare. Crea prima da “Create”.';
      });
      return;
    }
    setState(() {
      _status = BumpStatus.sent;
      _msg = 'Segreto inviato (mock): ${v.secret.substring(0, 6)}...';
    });
  }

  void _reset() => setState(() {
    _status = BumpStatus.idle;
    _msg = null;
  });

  @override
  Widget build(BuildContext context) {
    final v = AppMemory.lastVoucher;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bump (Avvicina iPhone)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('Demo senza prossimità reale: simula discover → peer found → invia segreto.'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Inizia ricerca'),
                onPressed: _status == BumpStatus.discovering ? null : _startDiscover,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Invia codice'),
                onPressed: _status == BumpStatus.peerFound ? _sendSecret : null,
              ),
              TextButton.icon(icon: const Icon(Icons.restart_alt), label: const Text('Reset'), onPressed: _reset),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _status == BumpStatus.sent
                    ? Icons.check_circle
                    : _status == BumpStatus.error
                    ? Icons.error_outline
                    : _status == BumpStatus.peerFound
                    ? Icons.bluetooth_connected
                    : _status == BumpStatus.discovering
                    ? Icons.hourglass_bottom
                    : Icons.info_outline,
              ),
              title: Text(_status.toString().split('.').last),
              subtitle: _msg != null ? Text(_msg!) : null,
            ),
          ),
          const SizedBox(height: 12),
          if (v != null) Text('Ultimo buono: ${v.amount} ETH • h=${v.h.substring(0, 10)}...'),
        ],
      ),
    );
  }
}
