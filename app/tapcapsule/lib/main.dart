import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapcapsule/services/signer_service.dart';
import 'package:tapcapsule/services/demo_hints_service.dart';
import 'package:tapcapsule/ui/theme.dart';
import 'pages/create_page.dart';
import 'pages/bump_page.dart';
import 'pages/redeem_page.dart';
import 'config/app_config.dart';
import 'widgets/network_probe.dart';
import 'widgets/animated_background.dart';
import 'widgets/gradient_text.dart';
import 'widgets/demo_hint_popup.dart';

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
      title: 'CryptoBump',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: kIsWeb ? const _WebPhoneSimulator() : const _HomeShell(),
    );
  }
}

// Simula le dimensioni di un iPhone quando è su web
class _WebPhoneSimulator extends StatelessWidget {
  const _WebPhoneSimulator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              AppTheme.primary.withOpacity(0.08),
              const Color(0xFF0a0a0a),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo grande per il demo
              SizedBox(
                width: 400,
                child: Transform.translate(
                  offset: const Offset(-10, 0),
                  child: Center(
                    child: const AppLogo(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crypto Payments as Easy as a Handshake',
                style: TextStyle(
                  color: AppTheme.lightText.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              // iPhone simulator with demo hints
              ValueListenableBuilder<DemoHint?>(
                valueListenable: demoHints.currentHint,
                builder: (context, hint, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // iPhone simulator
                      Container(
                        width: 400, // Include border
                        height: 854, // Include border
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(55),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2A2A2A), // Dark titanium
                              const Color(0xFF1A1A1A),
                              const Color(0xFF2A2A2A),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.1),
                              blurRadius: 100,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          width: 390, // iPhone 14 Pro width
                          height: 844, // iPhone 14 Pro height
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: const _HomeShell(),
                        ),
                      ),
                      // Demo hint popup
                      if (hint != null)
                        Positioned(
                          left: hint.position == DemoHintPosition.left ? -320 :
                                hint.position == DemoHintPosition.right ? 420 : null,
                          right: hint.position == DemoHintPosition.right ? -320 : null,
                          top: hint.position == DemoHintPosition.top ? -120 :
                               hint.position == DemoHintPosition.bottom ? null : 400,
                          bottom: hint.position == DemoHintPosition.bottom ? -120 : null,
                          child: DemoHintPopup(hint: hint),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _showSignerSheet = false;
  bool _obscureKey = true;
  late AnimationController _sheetController;
  late Animation<double> _sheetAnimation;

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    setState(() => _index = index);
  }

  List<Widget> get _pages => [
    CreatePage(onNavigateToTab: _navigateToTab),
    BumpPage(onNavigateToTab: _navigateToTab),
    RedeemPage(onNavigateToTab: _navigateToTab),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          AnimatedBackground(
            child: SafeArea(
              child: Column(
                children: [
              // Header with glassmorphism
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Logo (smaller when wallet connected)
                    if (!signer.isReady) const AppLogo(fontSize: 18),
                    if (signer.isReady) ...[
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primary, AppTheme.secondary, AppTheme.accent],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcIn,
                        child: const Icon(
                          Icons.bolt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),

                    // Wallet (if connected)
                    if (signer.isReady) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.2),
                                AppTheme.accent.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet,
                                color: AppTheme.accent, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${signer.address!.hex.substring(0, 6)}...${signer.address!.hex.substring(signer.address!.hex.length - 4)}',
                                  style: const TextStyle(
                                    color: AppTheme.lightText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Network status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Base',
                          style: TextStyle(
                            color: AppTheme.lightText.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Connect/Change button
                    FilledButton.icon(
                      icon: const Icon(Icons.vpn_key_rounded, size: 13),
                      label: Text(signer.isReady ? 'Change' : 'Connect'),
                      onPressed: _openSignerSheet,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
                  Expanded(child: _pages[_index]),
                ],
              ),
            ),
          ),
          // Custom bottom sheet for web
          if (kIsWeb && _showSignerSheet)
            GestureDetector(
              onTap: () {
                setState(() => _showSignerSheet = false);
                _sheetController.reverse();
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          if (kIsWeb && _showSignerSheet)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80, // Position above navigation bar
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_sheetAnimation),
                child: _buildSignerSheetContent(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: '',
            ),
          ],
          onDestinationSelected: (i) {
            setState(() => _index = i);

            // Show demo hint when switching to Redeem tab
            if (kIsWeb && i == 2) {
              demoHints.show(
                'Receiver\'s iPhone: Secret received via encrypted Multipeer connection',
                position: DemoHintPosition.right,
              );
              Future.delayed(const Duration(seconds: 3), () {
                if (kIsWeb) demoHints.hide();
              });
            }
          },
        ),
      ),
    );
  }

  void _openSignerSheet() {
    if (kIsWeb) {
      demoHints.show(
        'Connect your wallet by entering a private key for testing',
        position: DemoHintPosition.right,
      );
      setState(() => _showSignerSheet = true);
      _sheetController.forward();
      return;
    }

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
                            if (kIsWeb) {
                              demoHints.show(
                                'Wallet connected! Now you can create vouchers or redeem them',
                                position: DemoHintPosition.right,
                              );
                              Future.delayed(const Duration(seconds: 3), () {
                                if (kIsWeb) demoHints.hide();
                              });
                            }
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);
                          } catch (_) {
                            if (!kIsWeb) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invalid key')));
                            }
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

  Widget _buildSignerSheetContent() {
    final ctrl = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Test Wallet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  signer.isReady
                    ? 'Current: ${signer.address!.hex.substring(0, 10)}…'
                    : 'Paste the private key (RAM only).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(.6)
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  obscureText: _obscureKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Private key',
                    hintText: '0x…',
                    prefixIcon: const Icon(Icons.vpn_key_rounded),
                    helperText: 'Not saved to disk',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      tooltip: _obscureKey ? 'Show' : 'Hide',
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
                        if (data?.text != null) setState(() => ctrl.text = data!.text!.trim());
                      },
                    ),
                    const Spacer(),
                    if (signer.isReady)
                      TextButton(
                        child: const Text('Remove key'),
                        onPressed: () {
                          signer.clear();
                          setState(() {
                            _showSignerSheet = false;
                          });
                          _sheetController.reverse();
                        },
                      ),
                    FilledButton(
                      child: const Text('Use this key'),
                      onPressed: () async {
                        try {
                          await signer.setPrivateKey(ctrl.text.trim());
                          if (kIsWeb) {
                            demoHints.show(
                              'Wallet connected! Now you can create vouchers or redeem them',
                              position: DemoHintPosition.right,
                            );
                            Future.delayed(const Duration(seconds: 3), () {
                              if (kIsWeb) demoHints.hide();
                            });
                          }
                          setState(() {
                            _showSignerSheet = false;
                          });
                          _sheetController.reverse();
                        } catch (_) {
                          // Error handled silently on web for demo
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
