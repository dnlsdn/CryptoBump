import 'package:flutter/material.dart';
import 'package:tapcapsule/services/signer_service.dart';
import 'package:web3dart/crypto.dart' as crypto; // keccak256 + bytesToHex

import '../models/voucher.dart';
import '../state/app_memory.dart';

import '../eth/contract_client.dart'; // adegua il path se diverso
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

  @override
  Widget build(BuildContext context) {
    final v = AppMemory.lastVoucher;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Create (Crea buono)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // === NEW: riga per gestire il signer
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
          const SizedBox(height: 12),

          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Importo (ETH)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Scadenza'),
            subtitle: Text(_expiry.toLocal().toString()),
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifica'),
              onPressed: _pickExpiry,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Crea buono'),
            onPressed: _status == OpStatus.working ? null : _createOnChain,
          ),
          const SizedBox(height: 12),
          _StatusBanner(status: _status, message: _msg),

          if (v != null && _status == OpStatus.success) ...[
            const Divider(height: 28),
            const Text('Dettagli ultimo buono'),
            Text('importo previsto: ${v.amount} ETH'),
            Text('expiry: ${v.expiry.toLocal()}'),
            Text('h (keccak256): ${v.h}'),
            Text('secret (base64url): ${v.secret}'),
            const SizedBox(height: 8),
            const Text('⚠️ Solo per test: non persistere il segreto su disco.'),
          ],

          if (_status == OpStatus.success && AppConfig.I.explorerBaseUrl.isNotEmpty && _msg != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Apri tx su explorer'),
              onPressed: () {
                final parts = _msg!.split('tx: ');
                if (parts.length == 2) {
                  final tx = parts[1];
                  final url = '${AppConfig.I.explorerBaseUrl}/tx/$tx';
                  debugPrint('Explorer URL: $url');
                  // Se vuoi aprirlo direttamente:
                  // await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ],
      ),
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
