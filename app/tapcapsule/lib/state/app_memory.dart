import '../models/voucher.dart';

class AppMemory {
  static Voucher? lastVoucher;

  static BumpPayload? lastBumpPayload;
  static String? lastCreateTx;
  static String? lastRedeemTx;
  static String? lastRefundTx;

  static void clearAll() {
    lastVoucher = null;
    lastBumpPayload = null;
  }
}
