import 'package:flutter/material.dart';

class BumpPage extends StatelessWidget {
  const BumpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Bump (Avvicina iPhone)',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}
