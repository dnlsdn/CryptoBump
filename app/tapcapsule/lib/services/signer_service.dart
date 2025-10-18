// lib/services/signer_service.dart
import 'package:web3dart/web3dart.dart';

class SignerService {
  Credentials? _creds;
  EthereumAddress? _addr;

  bool get isReady => _creds != null;
  EthereumAddress? get address => _addr;

  /// Imposta una private key esadecimale (solo test! NON persistiamo nulla)
  Future<void> setPrivateKey(String hex) async {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    final c = EthPrivateKey.fromHex(clean);
    _addr = await c.extractAddress();
    _creds = c;
  }

  void clear() {
    _creds = null;
    _addr = null;
  }

  Credentials requireCreds() {
    final c = _creds;
    if (c == null) {
      throw StateError('Nessun signer impostato. Inserisci la chiave privata di un wallet di test.');
    }
    return c;
  }
}

final signer = SignerService();
