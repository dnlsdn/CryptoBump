import 'dart:math';

BigInt ethToWeiDouble(double eth) {
  final s = (eth * pow(10, 18)).toStringAsFixed(0);
  return BigInt.parse(s);
}
