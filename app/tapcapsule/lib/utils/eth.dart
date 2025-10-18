import 'dart:math';

BigInt ethToWeiDouble(double eth) {
  // evita problemi di double usando stringhe a 18 decimali
  final s = (eth * pow(10, 18)).toStringAsFixed(0);
  return BigInt.parse(s);
}
