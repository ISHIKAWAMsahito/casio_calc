import 'package:decimal/decimal.dart';

/// グランドトータル（GT）を管理する純粋Dartクラス。
///
/// 仕様:
/// - [=] で確定した計算結果を自動的に加算する ([addResult])
/// - [GT] キー押下でGT値を呼び出す ([peek])
/// - [GT] を2回連続で押す、または [AC] を押すとクリアされる
class GtManager {
  Decimal _total = Decimal.zero;
  bool _lastActionWasGtPeek = false;

  Decimal get total => _total;
  bool get hasValue => _total != Decimal.zero;

  /// [=] 確定時に呼ぶ。GTバッファに加算する。
  void addResult(Decimal result) {
    _total += result;
    _lastActionWasGtPeek = false;
  }

  /// [GT] キー押下時の処理。
  /// 直前もGT押下だった場合はクリアして0を返す（2回連続押下でクリア仕様）。
  Decimal peekOrClear() {
    if (_lastActionWasGtPeek) {
      _total = Decimal.zero;
      _lastActionWasGtPeek = false;
      return _total;
    }
    _lastActionWasGtPeek = true;
    return _total;
  }

  /// [AC] などで明示的にクリアする。
  void clear() {
    _total = Decimal.zero;
    _lastActionWasGtPeek = false;
  }

  /// GT以外のキーが押されたら「連続GT押下」の状態をリセットする。
  void notifyOtherKeyPressed() {
    _lastActionWasGtPeek = false;
  }
}
