import 'dart:convert';
import 'dart:math';

enum OpStatus { idle, working, success, error }

class Voucher {
  final double amount; // in ETH (testnet, solo display)
  final DateTime expiry;
  final String secret; // ⚠️ demo: non persistiamo su disco
  final String h; // demo-hash (placeholder, NON keccak)

  Voucher({required this.amount, required this.expiry, required this.secret, required this.h});

  static String genSecret({int bytes = 16}) {
    final r = Random.secure();
    final data = List<int>.generate(bytes, (_) => r.nextInt(256));
    return base64Url.encode(data);
  }

  static String fakeHash(String secret) {
    // Placeholder: NON usare in produzione. Metteremo keccak in Fase 3.
    return 'h_${secret.hashCode.toRadixString(16)}';
  }
}
