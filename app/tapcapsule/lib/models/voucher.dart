import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart' as w3;

/// Stati operativi generici per UI (create/redeem)
enum OpStatus { idle, working, success, error }

/// Dati minimi del Voucher lato app.
/// - amount: in ETH (testnet), solo per UI
/// - expiry: scadenza assoluta
/// - secret: codice da passare via prossimità (⚠️ non persistere su disco)
/// - h: hash keccak256(secret) in esadecimale 0x-prefixed (64 hex chars)
class Voucher {
  final double amount;
  final DateTime expiry;
  final String secret; // base64url del segreto random (solo per trasporto UI)
  final String h; // 0x + 64 hex (keccak256(secret_bytes))

  const Voucher({required this.amount, required this.expiry, required this.secret, required this.h});

  /// Genera bytes casuali per il secret (di default 32 byte).
  static Uint8List genSecretBytes({int bytes = 32}) {
    final r = Random.secure();
    final data = List<int>.generate(bytes, (_) => r.nextInt(256));
    return Uint8List.fromList(data);
  }

  /// Codifica i bytes del secret in base64url (comodo da mostrare/trasportare).
  static String encodeSecretB64Url(Uint8List bytes) => base64Url.encode(bytes);

  /// Calcola keccak256 dei bytes del secret e ritorna "0x...".
  static String keccakHex(Uint8List secretBytes) {
    final digest = w3.keccak256(secretBytes);
    return w3.bytesToHex(digest, include0x: true);
  }

  /// Se hai già il secret in base64url, prova a decodificarlo e calcolare keccak.
  /// In fallback (raro), se la decode fallisce, usa keccak su UTF-8 del testo.
  static String keccakFromB64Url(String secretB64) {
    try {
      final b = base64Url.decode(secretB64);
      return keccakHex(Uint8List.fromList(b));
    } catch (_) {
      final utf8Digest = w3.keccakUtf8(secretB64);
      return w3.bytesToHex(utf8Digest, include0x: true);
    }
  }

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
  final String secret; // base64url
  final String h; // 0x + 64 hex
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
