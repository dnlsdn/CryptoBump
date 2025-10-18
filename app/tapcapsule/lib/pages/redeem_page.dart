import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapcapsule/config/app_config.dart';
import 'package:tapcapsule/pages/bump_page.dart';
import 'package:tapcapsule/services/contract_client.dart';
import 'package:tapcapsule/services/signer_service.dart';
import 'package:tapcapsule/utils/ui_safety.dart';
import 'package:tapcapsule/widgets/section_card.dart';
import '../models/voucher.dart';
import '../state/app_memory.dart';

class RedeemPage extends StatefulWidget {
  final String? secretPrefill;
  final bool autoRedeem;

  const RedeemPage({super.key, this.secretPrefill, this.autoRedeem = false});
  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final _secretCtrl = TextEditingController();
  OpStatus _status = OpStatus.idle;
  String? _msg;

  Future<void> _redeemOnChain() async {
    hideAllTextMenusAndKeyboard();
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
    // prefill da bump, oppure dai fallback che già avevi
    final p = AppMemory.lastBumpPayload;
    final v = AppMemory.lastVoucher;
    _secretCtrl.text = widget.secretPrefill ?? p?.secret ?? v?.secret ?? '';

    // auto-redeem appena la UI è pronta
    if (widget.autoRedeem && _secretCtrl.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        hideAllTextMenusAndKeyboard();
        _redeemOnChain();
      });
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        stepChips(2),
        const SizedBox(height: 12),

        if (p != null || v != null)
          SectionCard(
            title: 'Dettagli previsti',
            children: [
              Text(
                '${(p?.amount ?? v!.amount)} ETH',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Chip(label: Text('Scade: ${(p?.expiry ?? v!.expiry).toLocal()}')),
            ],
          ),

        SectionCard(
          title: 'Incassa buono',
          caption: 'Inserisci o incolla il codice segreto ricevuto.',
          children: [
            TextField(
              controller: _secretCtrl,
              decoration: InputDecoration(
                labelText: 'Codice segreto',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    hideAllTextMenusAndKeyboard();
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) _secretCtrl.text = data!.text!;
                  },
                ),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download_done_outlined),
              label: const Text('Incassa ora'),
              onPressed: _status == OpStatus.working ? null : _redeemOnChain,
            ),
          ],
        ),

        const SizedBox(height: 8),
        _Status(status: _status, msg: _msg),

        if (_status == OpStatus.success && _msg?.contains('tx: ') == true)
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
