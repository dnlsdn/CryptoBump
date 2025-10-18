import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../state/app_memory.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});
  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final _secretCtrl = TextEditingController();
  OpStatus _status = OpStatus.idle;
  String? _msg;

  @override
  void initState() {
    super.initState();
    final v = AppMemory.lastVoucher;
    final p = AppMemory.lastBumpPayload;
    if (v != null) _secretCtrl.text = v.secret; // demo: auto-precompila
  }

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeemMock() async {
    FocusScope.of(context).unfocus();
    final input = _secretCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Inserisci il codice segreto.';
      });
      return;
    }
    setState(() {
      _status = OpStatus.working;
      _msg = null;
    });
    await Future.delayed(const Duration(seconds: 1));

    final v = AppMemory.lastVoucher;
    if (v != null && input == v.secret) {
      setState(() {
        _status = OpStatus.success;
        _msg = 'Incassato (mock). Apri explorer nella Fase 3.';
      });
    } else {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Segreto errato o buono non trovato.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = AppMemory.lastVoucher;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Redeem (Incassa)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          if (v != null) ...[
            const SizedBox(height: 8),
            Text('Previsto: ${v.amount} ETH • scade: ${v.expiry.toLocal()}'),
          ] else if (v != null) ...[
            const SizedBox(height: 8),
            Text('Previsto: ${v.amount} ETH • scade: ${v.expiry.toLocal()}'),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _secretCtrl,
            decoration: const InputDecoration(labelText: 'Codice segreto', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.download_done_outlined),
            label: const Text('Incassa (mock)'),
            onPressed: _status == OpStatus.working ? null : _redeemMock,
          ),
          const SizedBox(height: 12),
          _Status(status: _status, msg: _msg),
          if (_status == OpStatus.success) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Apri su explorer (placeholder)'),
              onPressed: null, // si abilita in Fase 3 con URL reale
            ),
          ],
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final OpStatus status;
  final String? msg;
  const _Status({required this.status, this.msg});
  @override
  Widget build(BuildContext context) {
    if (status == OpStatus.idle) return const SizedBox.shrink();
    final title = switch (status) {
      OpStatus.working => 'In corso...',
      OpStatus.success => 'Fatto!',
      OpStatus.error => 'Errore',
      _ => '',
    };
    return Card(
      child: ListTile(
        leading: Icon(
          status == OpStatus.success
              ? Icons.check_circle
              : status == OpStatus.error
              ? Icons.error_outline
              : Icons.hourglass_bottom,
        ),
        title: Text(title),
        subtitle: msg != null ? Text(msg!) : null,
      ),
    );
  }
}
