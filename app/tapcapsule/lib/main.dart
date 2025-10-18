import 'package:flutter/material.dart';
import 'pages/create_page.dart';
import 'pages/bump_page.dart';
import 'pages/redeem_page.dart';

void main() {
  runApp(const TapCapsuleApp());
}

class TapCapsuleApp extends StatelessWidget {
  const TapCapsuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapCapsule',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2058FF)), useMaterial3: true),
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({super.key});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  static const _titles = ['Create', 'Bump', 'Redeem'];
  static const _pages = <Widget>[CreatePage(), BumpPage(), RedeemPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.near_me_outlined), label: 'Bump'),
          NavigationDestination(icon: Icon(Icons.download_done_outlined), label: 'Redeem'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
