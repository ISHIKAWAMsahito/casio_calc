import 'package:decimal/decimal.dart';

/// ディスプレイ表示用のフォーマットを行うユーティリティ。
/// 3桁区切りカンマ表示・12桁制限のチェックを担当する。
class DisplayFormatter {
  static const int maxDigits = 12;

  /// Decimal値を「3桁区切りカンマ付き」文字列に変換する。
  /// 例: 1234567 -> "1,234,567"
  ///     1234.5  -> "1,234.5"
  static String format(Decimal value) {
    final isNegative = value < Decimal.zero;
    final abs = value.abs();

    final str = abs.toString();
    final parts = str.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : null;

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    var result = buffer.toString();
    if (fracPart != null && fracPart.isNotEmpty) {
      result = '$result.$fracPart';
    }
    if (isNegative && value != Decimal.zero) {
      result = '-$result';
    }
    return result;
  }

  /// 入力中の生文字列（カンマなし）が最大桁数を超えているか判定する。
  static bool exceedsMaxDigits(String rawDigitsOnly) {
    final digitsOnly =
        rawDigitsOnly.replaceAll('.', '').replaceAll('-', '');
    return digitsOnly.length > maxDigits;
  }
}
