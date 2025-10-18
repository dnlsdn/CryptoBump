import '../models/voucher.dart';

/// Memoria process-local (solo per demo/MVP).
/// ⚠️ Non persiste su disco il segreto.
class AppMemory {
  /// Ultimo voucher creato localmente (lato “sender”).
  static Voucher? lastVoucher;

  /// Ultimo payload effimero inviato o ricevuto via prossimità.
  /// - lato sender: BumpPayload.fromVoucher(lastVoucher)
  /// - lato receiver: payload ricevuto (secret+h+amount+expiry)
  static BumpPayload? lastBumpPayload;

  static void clearAll() {
    lastVoucher = null;
    lastBumpPayload = null;
  }
}
