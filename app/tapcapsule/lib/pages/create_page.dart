import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapcapsule/pages/bump_page.dart';
import 'package:tapcapsule/services/contract_client.dart';
import 'package:tapcapsule/services/signer_service.dart';
import 'package:tapcapsule/utils/ui_safety.dart';
import 'package:tapcapsule/widgets/section_card.dart';
import 'package:web3dart/crypto.dart' as crypto; // keccak256 + bytesToHex
import '../models/voucher.dart';
import '../state/app_memory.dart';
import '../utils/eth.dart'; // contiene ethToWeiDouble(…)
import '../config/app_config.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});
  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _amountCtrl = TextEditingController(text: '0.005'); // ETH demo
  DateTime _expiry = DateTime.now().add(const Duration(hours: 24));
  OpStatus _status = OpStatus.idle;
  String? _msg;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    hideAllTextMenusAndKeyboard();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_expiry));
    final chosen = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _expiry.hour,
      time?.minute ?? _expiry.minute,
    );
    setState(() => _expiry = chosen);
  }

  // === NEW: dialog per impostare la private key del wallet di test (solo RAM)
  Future<void> _setPkDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Imposta private key (testnet)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '0x...'),
          obscureText: true,
          autofocus: true,
          onTapOutside: (_) => hideAllTextMenusAndKeyboard(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usa')),
        ],
      ),
    );
    if (ok == true) {
      await signer.setPrivateKey(ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signer impostato: ${signer.address}')));
      setState(() {});
    }
  }

  Future<void> _createOnChain() async {
    hideAllTextMenusAndKeyboard();
    FocusScope.of(context).unfocus();
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Inserisci un importo valido (> 0)';
      });
      return;
    }
    if (!signer.isReady) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Nessun signer. Premi “Imposta chiave privata” e incolla la PK del wallet di test.';
      });
      return;
    }

    setState(() {
      _status = OpStatus.working;
      _msg = 'Creazione in corso…';
    });

    try {
      // 1) Segreto + hash (bytes32)
      final secretBytes = Voucher.genSecretBytes(bytes: 32); // Uint8List
      final secretB64 = Voucher.encodeSecretB64Url(secretBytes);
      final hBytes = crypto.keccak256(secretBytes); // List<int> (32)
      final hHex = crypto.bytesToHex(hBytes, include0x: true);

      // 2) Importo e scadenza
      final amountWei = ethToWeiDouble(amt); // BigInt
      final expiry = BigInt.from(_expiry.millisecondsSinceEpoch ~/ 1000);

      // 3) Client + credenziali (dal signer, non burner)
      final cc = await ContractClient.create();
      final creds = signer.requireCreds();

      // 4) Chiamata on-chain
      final txHash = await cc.createVoucherETH(
        hBytes: hBytes as dynamic, // web3dart accetta Uint8List/List<int>
        amountWei: amountWei,
        expiry: expiry,
        creds: creds,
      );
      cc.dispose();

      // 5) Aggiorna memoria UI
      final v = Voucher(amount: amt, expiry: _expiry, secret: secretB64, h: hHex);
      AppMemory.lastVoucher = v;

      setState(() {
        _status = OpStatus.success;
        _msg = 'Creato! tx: $txHash';
      });
    } catch (e) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Errore creazione: $e';
      });
    }
  }

  Future<void> _refund() async {
    hideAllTextMenusAndKeyboard();
    final v = AppMemory.lastVoucher;
    if (v == null) return;

    if (!signer.isReady) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Nessun signer. Imposta la chiave privata di test.';
      });
      return;
    }

    setState(() {
      _status = OpStatus.working;
      _msg = 'Annullamento in corso…';
    });

    try {
      // h: "0x" + 64 hex -> bytes32
      final hexNo0x = v.h.startsWith('0x') ? v.h.substring(2) : v.h;
      final hBytes = Uint8List.fromList(crypto.hexToBytes(hexNo0x));

      final cc = await ContractClient.create();
      final tx = await cc.refund(hBytes: hBytes, creds: signer.requireCreds());
      cc.dispose();

      AppMemory.lastRefundTx = tx;
      // svuota la memoria locale del buono
      AppMemory.lastVoucher = null;

      setState(() {
        _status = OpStatus.success;
        _msg = 'Rimborsato! tx: $tx';
      });
    } catch (e) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Errore refund: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        stepChips(0),
        const SizedBox(height: 12),

        SectionCard(
          title: 'Crea un buono',
          caption: 'Blocca ETH fino alla scadenza. Il destinatario incassa col codice segreto.',
          children: [
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.vpn_key),
                  label: Text(signer.isReady ? 'Signer pronto' : 'Imposta chiave privata'),
                  onPressed: _setPkDialog,
                ),
                const SizedBox(width: 8),
                if (signer.isReady)
                  Text('${signer.address!.hex.substring(0, 10)}…', style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Importo', prefixText: 'Ξ ', helperText: 'Esempio 0.005'),
              onTapOutside: (_) => hideAllTextMenusAndKeyboard(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scadenza'),
              subtitle: Text(_expiry.toLocal().toString()),
              trailing: FilledButton.tonalIcon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifica'),
                onPressed: _pickExpiry,
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Crea buono'),
              onPressed: _status == OpStatus.working ? null : _createOnChain,
            ),
          ],
        ),

        const SizedBox(height: 8),
        _StatusBanner(status: _status, message: _msg),

        if (AppMemory.lastVoucher != null) ...[
          const SizedBox(height: 8),
          SectionCard(
            title: 'Ultimo buono',
            trailing: IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: AppMemory.lastVoucher!.isExpired
                  ? 'Annulla buono e riprendi i fondi'
                  : 'Disponibile dopo la scadenza',
              color: AppMemory.lastVoucher!.isExpired ? Theme.of(context).colorScheme.error : null,
              onPressed: (_status == OpStatus.working || !AppMemory.lastVoucher!.isExpired) ? null : _refund,
            ),
            children: [
              Text(
                '${AppMemory.lastVoucher!.amount} ETH',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Scade: ${AppMemory.lastVoucher!.expiry.toLocal()}')),
                  Chip(label: Text('h: ${AppMemory.lastVoucher!.shortH}')),
                ],
              ),
              SelectableText(
                'secret: ${AppMemory.lastVoucher!.secret}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copia secret'),
                    onPressed: () {
                      hideAllTextMenusAndKeyboard();
                      Clipboard.setData(ClipboardData(text: AppMemory.lastVoucher!.secret));
                    },
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.near_me_outlined),
                    label: const Text('Passa a Bump'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BumpPage())),
                  ),
                ],
              ),
            ],
          ),
        ],

        if (_status == OpStatus.success && AppConfig.I.explorerBaseUrl.isNotEmpty && _msg != null)
          TextButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apri tx su explorer'),
            onPressed: () {
              final parts = _msg!.split('tx: ');
              if (parts.length == 2) {
                final tx = parts[1];
                final url = '${AppConfig.I.explorerBaseUrl}/tx/$tx';
                debugPrint('Explorer URL: $url');
              }
            },
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OpStatus status;
  final String? message;
  const _StatusBanner({required this.status, this.message});

  @override
  Widget build(BuildContext context) {
    if (status == OpStatus.idle) return const SizedBox.shrink();
    final text = switch (status) {
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
        title: Text(text),
        subtitle: message != null ? Text(message!) : null,
      ),
    );
  }
}
