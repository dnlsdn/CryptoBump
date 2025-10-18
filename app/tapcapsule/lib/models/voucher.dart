import 'dart:convert';
import 'dart:math';

/// Stati operativi generici per UI (create/redeem)
enum OpStatus { idle, working, success, error }

/// Dati minimi del Voucher lato app.
/// - amount: in ETH (testnet), solo per UI
/// - expiry: scadenza assoluta
/// - secret: codice da passare via prossimità (⚠️ non persistere su disco)
/// - h: hash del segreto (placeholder per ora, keccak in Fase 3)
class Voucher {
  final double amount;
  final DateTime expiry;
  final String secret;
  final String h;

  const Voucher({required this.amount, required this.expiry, required this.secret, required this.h});

  /// Genera un segreto URL-safe (base64url) — *solo in demo*.
  static String genSecret({int bytes = 16}) {
    final r = Random.secure();
    final data = List<int>.generate(bytes, (_) => r.nextInt(256));
    return base64Url.encode(data);
  }

  /// Placeholder di hash (NON usare in produzione).
  /// In Fase 3 sostituiremo con keccak256(secret).
  static String fakeHash(String secret) => 'h_${secret.hashCode.toRadixString(16)}';

  // -------- Helper UI --------
  bool get isExpired => DateTime.now().isAfter(expiry);
  Duration get ttl => expiry.difference(DateTime.now());
  String get shortH => h.length > 10 ? '${h.substring(0, 10)}…' : h;
  String get shortSecret => secret.length > 6 ? '${secret.substring(0, 6)}…' : secret;

  // -------- (De)serializzazione per futuro QR / Multipeer --------
  Map<String, dynamic> toJson() => {'amount': amount, 'expiry': expiry.toIso8601String(), 'secret': secret, 'h': h};

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    amount: (json['amount'] as num).toDouble(),
    expiry: DateTime.parse(json['expiry'] as String),
    secret: json['secret'] as String,
    h: json['h'] as String,
  );

  Voucher copyWith({double? amount, DateTime? expiry, String? secret, String? h}) => Voucher(
    amount: amount ?? this.amount,
    expiry: expiry ?? this.expiry,
    secret: secret ?? this.secret,
    h: h ?? this.h,
  );
}

/// Payload “effimero” da inviare al destinatario in prossimità.
/// Contiene SOLO ciò che serve a incassare e mostrare i dettagli attesi.
class BumpPayload {
  final String secret;
  final String h;
  final double amount;
  final DateTime expiry;

  const BumpPayload({required this.secret, required this.h, required this.amount, required this.expiry});

  factory BumpPayload.fromVoucher(Voucher v) =>
      BumpPayload(secret: v.secret, h: v.h, amount: v.amount, expiry: v.expiry);

  Map<String, dynamic> toJson() => {'secret': secret, 'h': h, 'amount': amount, 'expiry': expiry.toIso8601String()};

  factory BumpPayload.fromJson(Map<String, dynamic> json) => BumpPayload(
    secret: json['secret'] as String,
    h: json['h'] as String,
    amount: (json['amount'] as num).toDouble(),
    expiry: DateTime.parse(json['expiry'] as String),
  );
}
