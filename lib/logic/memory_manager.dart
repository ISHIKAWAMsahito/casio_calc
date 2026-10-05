import 'package:decimal/decimal.dart';

/// 独立4キーメモリ（MC / MR / M- / M+）を管理する純粋Dartクラス。
///
/// カシオ実機の「独立メモリ」方式:
/// - M+: 表示値を加算
/// - M-: 表示値を減算
/// - MR: メモリ値を呼び出す（表示するだけで、メモリ自体は変化しない）
/// - MC: メモリ値をゼロクリア（1回押下で即クリア）
class MemoryManager {
  Decimal _memory = Decimal.zero;

  Decimal get memory => _memory;

  /// メモリに値が入っている間、ディスプレイに `M` インジケータを表示する。
  bool get hasMemory => _memory != Decimal.zero;

  void memoryPlus(Decimal value) {
    _memory += value;
  }

  void memoryMinus(Decimal value) {
    _memory -= value;
  }

  Decimal memoryRecall() => _memory;

  void memoryClear() {
    _memory = Decimal.zero;
  }
}
