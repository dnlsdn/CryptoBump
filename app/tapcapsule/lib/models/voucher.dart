import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:web3dart/crypto.dart' as w3;

enum OpStatus { idle, working, success, error }
class Voucher {
  final double amount;
  final DateTime expiry;
  final String secret;
  final String h;

  const Voucher({required this.amount, required this.expiry, required this.secret, required this.h});

  static Uint8List genSecretBytes({int bytes = 32}) {
    final r = Random.secure();
    final data = List<int>.generate(bytes, (_) => r.nextInt(256));
    return Uint8List.fromList(data);
  }

  static String encodeSecretB64Url(Uint8List bytes) => base64Url.encode(bytes);

  static String keccakHex(Uint8List secretBytes) {
    final digest = w3.keccak256(secretBytes);
    return w3.bytesToHex(digest, include0x: true);
  }

  static String keccakFromB64Url(String secretB64) {
    try {
      final b = base64Url.decode(secretB64);
      return keccakHex(Uint8List.fromList(b));
    } catch (_) {
      final utf8Digest = w3.keccakUtf8(secretB64);
      return w3.bytesToHex(utf8Digest, include0x: true);
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiry);
  Duration get ttl => expiry.difference(DateTime.now());
  String get shortH => h.length > 10 ? '${h.substring(0, 10)}…' : h;
  String get shortSecret => secret.length > 6 ? '${secret.substring(0, 6)}…' : secret;

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
