import 'package:decimal/decimal.dart';

/// 四則演算の種類
enum Operator { add, subtract, multiply, divide, none }

/// 電卓の計算結果。
/// [isError] が true の場合、桁あふれ・ゼロ除算等が発生している。
class CalcResult {
  final Decimal value;
  final bool isError;
  final String? errorMessage;

  const CalcResult(this.value, {this.isError = false, this.errorMessage});

  factory CalcResult.error(String message) =>
      CalcResult(Decimal.zero, isError: true, errorMessage: message);
}

/// カシオ実機ライクな「逐次計算（チェーン計算）」を行う純粋Dartロジック。
///
/// 例: 1 [+] 2 [×] 3 [=]
///   -> 1+2 が押した時点で評価され 3 になる (accumulator=3, operator=multiply)
///   -> 3×3 = 9 が [=] で確定する
///
/// 浮動小数点誤差を避けるため、全ての値は [Decimal] 型で保持する。
class CalculatorEngine {
  static const int maxDigits = 12;

  /// 現在の途中計算結果（左辺）
  Decimal _accumulator = Decimal.zero;

  /// 保留中の演算子
  Operator _pendingOperator = Operator.none;

  /// 直近の右辺（%計算・繰り返し=用に保持）
  Decimal _lastOperand = Decimal.zero;
  Operator _lastOperatorForRepeat = Operator.none;

  Decimal get accumulator => _accumulator;
  Operator get pendingOperator => _pendingOperator;

  /// 状態を完全リセットする（AC相当）。
  void reset() {
    _accumulator = Decimal.zero;
    _pendingOperator = Operator.none;
    _lastOperand = Decimal.zero;
    _lastOperatorForRepeat = Operator.none;
  }

  /// 演算子キーが押された時の処理。
  /// 保留中の演算があればまず確定し、新しい演算子を保留にする。
  CalcResult inputOperator(Decimal currentDisplay, Operator op) {
    if (_pendingOperator == Operator.none) {
      _accumulator = currentDisplay;
    } else {
      final result = _applyOperator(
          _accumulator, currentDisplay, _pendingOperator);
      if (result.isError) return result;
      _accumulator = result.value;
    }
    _pendingOperator = op;
    return CalcResult(_accumulator);
  }

  /// [=] キー押下時の処理。結果を確定して返す。
  /// 演算子が保留されていない状態で連続して[=]を押した場合は、
  /// 直前の演算子・オペランドを使って「繰り返し計算」を行う（実機電卓の挙動）。
  CalcResult inputEquals(Decimal currentDisplay) {
    Operator opToApply;
    Decimal operand;

    if (_pendingOperator != Operator.none) {
      opToApply = _pendingOperator;
      operand = currentDisplay;
      _lastOperatorForRepeat = opToApply;
      _lastOperand = operand;
    } else if (_lastOperatorForRepeat != Operator.none) {
      // 例: 5 + 3 = = = ... のような連続イコール
      opToApply = _lastOperatorForRepeat;
      operand = _lastOperand;
      _accumulator = currentDisplay;
    } else {
      // 演算子未入力のまま = を押した場合は入力値をそのまま返す
      _accumulator = currentDisplay;
      return CalcResult(_accumulator);
    }

    final result = _applyOperator(_accumulator, operand, opToApply);
    if (result.isError) return result;

    _accumulator = result.value;
    _pendingOperator = Operator.none;
    return CalcResult(_accumulator);
  }

  /// パーセントキーの処理。
  /// 直前に保留中の演算子があるかどうかで挙動が変わる（実務電卓の慣習に合わせる）。
  ///   1000 + 10 % -> 1000 + (1000*10/100) = 1100  （割増）
  ///   1000 - 10 % -> 1000 - (1000*10/100) = 900   （割引）
  ///   1000 × 10 % -> 1000 * (10/100) = 100        （比率計算）
  ///   1000 ÷ 10 % -> 1000 / (10/100) = 10000
  ///   演算子が無い場合は単純に /100 する。
  CalcResult inputPercent(Decimal currentDisplay) {
    if (_pendingOperator == Operator.none) {
      final value = currentDisplay / Decimal.fromInt(100);
      return CalcResult(value.toDecimal(scaleOnInfinitePrecision: 20));
    }

    switch (_pendingOperator) {
      case Operator.add:
        final delta =
            (_accumulator * currentDisplay / Decimal.fromInt(100))
                .toDecimal(scaleOnInfinitePrecision: 20);
        final result = _accumulator + delta;
        _accumulator = result;
        _pendingOperator = Operator.none;
        return _checkOverflow(result);
      case Operator.subtract:
        final delta =
            (_accumulator * currentDisplay / Decimal.fromInt(100))
                .toDecimal(scaleOnInfinitePrecision: 20);
        final result = _accumulator - delta;
        _accumulator = result;
        _pendingOperator = Operator.none;
        return _checkOverflow(result);
      case Operator.multiply:
        final ratio = (currentDisplay / Decimal.fromInt(100))
            .toDecimal(scaleOnInfinitePrecision: 20);
        final result = _accumulator * ratio;
        _accumulator = result;
        _pendingOperator = Operator.none;
        return _checkOverflow(result);
      case Operator.divide:
        if (currentDisplay == Decimal.zero) {
          return CalcResult.error('E');
        }
        final ratio = (currentDisplay / Decimal.fromInt(100))
            .toDecimal(scaleOnInfinitePrecision: 20);
        if (ratio == Decimal.zero) return CalcResult.error('E');
        final result =
            (_accumulator / ratio).toDecimal(scaleOnInfinitePrecision: 20);
        _accumulator = result;
        _pendingOperator = Operator.none;
        return _checkOverflow(result);
      case Operator.none:
        return CalcResult(currentDisplay);
    }
  }

  CalcResult _applyOperator(Decimal left, Decimal right, Operator op) {
    Decimal result;
    switch (op) {
      case Operator.add:
        result = left + right;
        break;
      case Operator.subtract:
        result = left - right;
        break;
      case Operator.multiply:
        result = left * right;
        break;
      case Operator.divide:
        if (right == Decimal.zero) {
          return CalcResult.error('E');
        }
        result = (left / right).toDecimal(scaleOnInfinitePrecision: 20);
        break;
      case Operator.none:
        result = right;
        break;
    }
    return _checkOverflow(result);
  }

  CalcResult _checkOverflow(Decimal value) {
    // 整数部の桁数チェック（符号・小数点は除く）
    final intPartDigits =
        value.abs().truncate().toString().replaceAll('-', '').length;
    if (intPartDigits > maxDigits) {
      return CalcResult.error('E');
    }
    return CalcResult(value);
  }

  /// 表示用に12桁を超えないか確認するユーティリティ（入力段階でも使用可能）。
  static bool exceedsMaxDigits(String digitsOnly) {
    return digitsOnly.replaceAll('.', '').replaceAll('-', '').length >
        maxDigits;
  }
}
