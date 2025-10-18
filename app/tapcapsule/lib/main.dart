import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapcapsule/services/signer_service.dart';
import 'package:tapcapsule/ui/theme.dart';
import 'pages/create_page.dart';
import 'pages/bump_page.dart';
import 'pages/redeem_page.dart';
import 'config/app_config.dart';
import 'widgets/network_probe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const TapCapsuleApp());
}

class TapCapsuleApp extends StatelessWidget {
  const TapCapsuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapCapsule',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[CreatePage(), BumpPage(), RedeemPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: NetworkProbe()),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (signer.isReady)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(label: Text('Wallet: ${signer.address!.hex.substring(0, 10)}…')),
                    ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: Text(signer.isReady ? 'Modifica wallet' : 'Imposta wallet'),
                    onPressed: _openSignerSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: ''),
          NavigationDestination(icon: Icon(Icons.near_me_outlined), label: ''),
          NavigationDestination(icon: Icon(Icons.download_done_outlined), label: ''),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }

  void _openSignerSheet() {
    final ctrl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Test Wallet',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    signer.isReady
                      ? 'Current: ${signer.address!.hex.substring(0, 10)}…'
                      : 'Paste the private key (RAM only).',
                    style: Theme.of(
                      ctx,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(.6)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: 'Private key',
                      hintText: '0x…',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                        helperText: 'Not saved to disk',
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModal(() => obscure = !obscure),
                        tooltip: obscure ? 'Show' : 'Hide',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.content_paste),
                        label: const Text('Paste'),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) setModal(() => ctrl.text = data!.text!.trim());
                        },
                      ),
                      const Spacer(),
                      if (signer.isReady)
                        TextButton(
                          child: const Text('Remove key'),
                          onPressed: () {
                            signer.clear();
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);
                          },
                        ),
                      FilledButton(
                        child: const Text('Use this key'),
                        onPressed: () async {
                          try {
                            await signer.setPrivateKey(ctrl.text.trim());
                            if (mounted) setState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('Signer set: ${signer.address}')));
                            }
                            Navigator.pop(ctx);
                          } catch (_) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invalid key')));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
