import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapcapsule/pages/bump_page.dart';
import 'package:tapcapsule/services/contract_client.dart';
import 'package:tapcapsule/services/signer_service.dart';
import 'package:tapcapsule/services/demo_hints_service.dart';
import 'package:tapcapsule/utils/ui_safety.dart';
import 'package:tapcapsule/widgets/section_card.dart';
import 'package:web3dart/crypto.dart' as crypto;
import '../models/voucher.dart';
import '../state/app_memory.dart';
import '../utils/eth.dart';
import '../config/app_config.dart';

class CreatePage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const CreatePage({super.key, this.onNavigateToTab});
  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _amountCtrl = TextEditingController(text: '0.005');
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
    DateTime temp = _expiry;

    final chosen = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SizedBox(
          height: 220 + MediaQuery.of(ctx).padding.bottom,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    TextButton(child: const Text('Annulla'), onPressed: () => Navigator.pop(ctx)),
                    const Spacer(),
                    TextButton(child: const Text('Fine'), onPressed: () => Navigator.pop(ctx, temp)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _expiry,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 30)),
                  use24hFormat: true,
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen != null) {
      setState(() => _expiry = chosen);
    }
  }

  Future<void> _createOnChain() async {
    if (kIsWeb) {
      demoHints.show(
        'Creating a crypto voucher on-chain with your specified amount',
        position: DemoHintPosition.right,
      );
    }

    hideAllTextMenusAndKeyboard();
    FocusScope.of(context).unfocus();
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Enter a valid amount (> 0)';
      });
      return;
    }
    if (!signer.isReady) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'No signer. Press "Set private key" and paste the test wallet PK.';
      });
      return;
    }

    setState(() {
      _status = OpStatus.working;
      _msg = 'Creating in progress...';
    });

    try {
      final secretBytes = Voucher.genSecretBytes(bytes: 32);
      final secretB64 = Voucher.encodeSecretB64Url(secretBytes);
      final hBytes = crypto.keccak256(secretBytes);
      final hHex = crypto.bytesToHex(hBytes, include0x: true);

      final amountWei = ethToWeiDouble(amt);
      final expiry = BigInt.from(_expiry.millisecondsSinceEpoch ~/ 1000);

      final cc = await ContractClient.create();
      final creds = signer.requireCreds();

      final txHash = await cc.createVoucherETH(
        hBytes: hBytes as dynamic,
        amountWei: amountWei,
        expiry: expiry,
        creds: creds,
      );
      cc.dispose();

      final v = Voucher(amount: amt, expiry: _expiry, secret: secretB64, h: hHex);
      AppMemory.lastVoucher = v;

      setState(() {
        _status = OpStatus.success;
        _msg = 'Created! tx: $txHash';
      });

      if (kIsWeb) {
        demoHints.show(
          'Voucher created on Base L2! Secret is ready to send via Multipeer',
          position: DemoHintPosition.right,
        );
        Future.delayed(const Duration(seconds: 4), () {
          if (kIsWeb) demoHints.hide();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: const Text('Voucher created'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Error creating: $e';
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
        _msg = 'No signer. Set the test private key.';
      });
      return;
    }

    setState(() {
      _status = OpStatus.working;
      _msg = 'Refund in progress...';
    });

    try {
      final hexNo0x = v.h.startsWith('0x') ? v.h.substring(2) : v.h;
      final hBytes = Uint8List.fromList(crypto.hexToBytes(hexNo0x));

      final cc = await ContractClient.create();
      final tx = await cc.refund(hBytes: hBytes, creds: signer.requireCreds());
      cc.dispose();

      AppMemory.lastRefundTx = tx;
      AppMemory.lastVoucher = null;

      setState(() {
        _status = OpStatus.success;
        _msg = 'Refunded! tx: $tx';
      });
    } catch (e) {
      setState(() {
        _status = OpStatus.error;
        _msg = 'Error refunding: $e';
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
          title: 'Create a voucher',
            caption: 'Lock ETH until expiry. The recipient cashes out with the secret code.',
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Import', prefixText: 'Ξ ', helperText: 'Example 0.005'),
              onTapOutside: (_) => hideAllTextMenusAndKeyboard(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry'),
              subtitle: Text(_expiry.toLocal().toString()),
              trailing: FilledButton.tonalIcon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                onPressed: _pickExpiry,
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Create Voucher'),
              onPressed: _status == OpStatus.working ? null : _createOnChain,
            ),
          ],
        ),

        const SizedBox(height: 8),
        _StatusBanner(status: _status, message: _msg),

        if (AppMemory.lastVoucher != null) ...[
          const SizedBox(height: 8),
          SectionCard(
            title: 'Last voucher',
            trailing: IconButton(
              icon: const Icon(Icons.cancel),
                tooltip: AppMemory.lastVoucher!.isExpired
                  ? 'Cancel voucher and reclaim funds'
                  : 'Available after expiry',
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
                  Chip(label: Text('Expires: ${AppMemory.lastVoucher!.expiry.toLocal()}')),
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
                    icon: const Icon(Icons.copy_all, size: 18),
                    label: const Text('Copy', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      hideAllTextMenusAndKeyboard();
                      Clipboard.setData(ClipboardData(text: AppMemory.lastVoucher!.secret));
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Send Nearby', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      if (kIsWeb) {
                        demoHints.show(
                          'Bump two iPhones to transfer the secret peer-to-peer via encrypted Multipeer',
                          position: DemoHintPosition.right,
                        );
                        Future.delayed(const Duration(seconds: 3), () {
                          if (kIsWeb) demoHints.hide();
                        });
                      }
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(1); // Navigate to Bump tab (index 1)
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],

        if (_status == OpStatus.success && AppConfig.I.explorerBaseUrl.isNotEmpty && _msg != null)
          TextButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open tx on explorer'),
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
      OpStatus.working => 'In progress...',
      OpStatus.success => 'Done!',
      OpStatus.error => 'Error',
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
