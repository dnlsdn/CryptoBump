import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapcapsule/config/app_config.dart';
import 'package:tapcapsule/services/contract_client.dart';
import 'package:tapcapsule/services/signer_service.dart';
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

  Future<void> _redeemOnChain() async {
    FocusScope.of(context).unfocus();
    final input = _secretCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Codice segreto mancante.';
      });
      return;
    }
    if (!signer.isReady) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Nessun signer. Imposta una chiave privata di test.';
      });
      return;
    }

    setState(() {
      _status = OpStatus.working;
      _msg = 'Invio redeem…';
    });

    try {
      Uint8List secretBytes;
      try {
        secretBytes = Uint8List.fromList(base64Url.decode(input));
      } catch (_) {
        secretBytes = Uint8List.fromList(utf8.encode(input));
      }

      final cc = await ContractClient.create();
      final tx = await cc.redeem(secretBytes: secretBytes, creds: signer.requireCreds());
      cc.dispose();

      AppMemory.lastRedeemTx = tx;
      setState(() {
        _status = OpStatus.success;
        _msg = 'Incassato! tx: $tx';
      });
    } catch (e) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Errore redeem: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final v = AppMemory.lastVoucher;
    final p = AppMemory.lastBumpPayload;
    if (p != null) {
      _secretCtrl.text = p.secret;
    } else if (v != null) {
      _secretCtrl.text = v.secret;
    }
  }

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppMemory.lastBumpPayload;
    final v = AppMemory.lastVoucher;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Redeem (Incassa)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          if (p != null) ...[
            const SizedBox(height: 8),
            Text('Previsto: ${p.amount} ETH • scade: ${p.expiry.toLocal()}'),
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
            label: const Text('Incassa ora'),
            onPressed: _status == OpStatus.working ? null : _redeemOnChain,
          ),
          const SizedBox(height: 12),
          _Status(status: _status, msg: _msg),
          if (_status == OpStatus.success && _msg?.contains('tx: ') == true) ...[
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Apri tx su explorer'),
              onPressed: () {
                final tx = _msg!.split('tx: ').last.trim();
                final url = '${AppConfig.I.explorerBaseUrl}/tx/$tx';
                debugPrint('Explorer URL: $url');
              },
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
