import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../state/app_memory.dart';

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

  Future<void> _createMock() async {
    FocusScope.of(context).unfocus();
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Inserisci un importo valido (> 0)';
      });
      return;
    }
    setState(() {
      _status = OpStatus.working;
      _msg = null;
    });

    await Future.delayed(const Duration(milliseconds: 400)); // piccola latenza UI

    // A2: segreto robusto (32 byte) + hash keccak256(secret_bytes)
    final secretBytes = Voucher.genSecretBytes(bytes: 32);
    final secretB64 = Voucher.encodeSecretB64Url(secretBytes);
    final h = Voucher.keccakHex(secretBytes);

    final v = Voucher(amount: amt, expiry: _expiry, secret: secretB64, h: h);
    AppMemory.lastVoucher = v;

    setState(() {
      _status = OpStatus.success;
      _msg = 'Buono (demo) pronto. Passa al tab “Bump”.';
    });
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
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Importo (ETH, solo display)', border: OutlineInputBorder()),
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
            label: const Text('Crea buono (mock)'),
            onPressed: _status == OpStatus.working ? null : _createMock,
          ),
          const SizedBox(height: 12),
          _StatusBanner(status: _status, message: _msg),

          // Riepilogo a schermo (come richiesto da A2)
          if (v != null && _status == OpStatus.success) ...[
            const Divider(height: 28),
            const Text('Dettagli ultimo buono (demo)'),
            Text('importo previsto: ${v.amount} ETH'),
            Text('expiry: ${v.expiry.toLocal()}'),
            Text('h (keccak256): ${v.h}'),
            Text('secret (base64url): ${v.secret}'),
            const SizedBox(height: 8),
            const Text('⚠️ Demo: il segreto è mostrato solo per test. Non persisterlo su disco.'),
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
