import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../logic/calculator_engine.dart';
import '../logic/display_formatter.dart';
import '../logic/gt_manager.dart';
import '../logic/memory_manager.dart';

/// 電卓画面全体の状態を管理するコントローラー。
/// ChangeNotifierを使い、Provider経由でUIに状態を配信する。
class CalculatorController extends ChangeNotifier {
  final CalculatorEngine _engine = CalculatorEngine();
  final MemoryManager _memoryManager = MemoryManager();
  final GtManager _gtManager = GtManager();

  /// 現在入力中の生文字列（カンマなし）。例: "1234", "12.5", "-8"
  String _inputBuffer = '0';

  /// 上段に表示する式・履歴文字列。
  String _expressionLine = '';

  /// 次の数字キー入力が新しい数値の開始かどうか。
  /// 演算子や[=]の直後はtrueになる。
  bool _startsNewEntry = true;

  bool _isError = false;

  // ---- Public getters (UI用) ----
  String get displayText =>
      _isError ? 'E' : DisplayFormatter.format(_currentDecimal());
  String get expressionLine => _expressionLine;
  bool get isError => _isError;
  bool get hasMemory => _memoryManager.hasMemory;
  bool get hasGt => _gtManager.hasValue;

  Decimal _currentDecimal() {
    if (_inputBuffer.isEmpty || _inputBuffer == '-') return Decimal.zero;
    return Decimal.parse(_inputBuffer);
  }

  String _operatorSymbol(Operator op) {
    switch (op) {
      case Operator.add:
        return '+';
      case Operator.subtract:
        return '-';
      case Operator.multiply:
        return '×';
      case Operator.divide:
        return '÷';
      case Operator.none:
        return '';
    }
  }

  // ---------------------------------------------------------------------
  // 数字・小数点入力
  // ---------------------------------------------------------------------

  void inputDigit(String digit) {
    if (_isError) return; // エラー中は AC 以外受け付けない
    _gtManager.notifyOtherKeyPressed();

    if (_startsNewEntry) {
      _inputBuffer = digit == '00' ? '0' : digit;
      _startsNewEntry = false;
    } else {
      if (_inputBuffer == '0' && digit != '.') {
        _inputBuffer = digit == '00' ? '0' : digit;
      } else {
        final candidate = _inputBuffer + digit;
        final digitsOnly = candidate.replaceAll('.', '').replaceAll('-', '');
        if (digitsOnly.length > CalculatorEngine.maxDigits) {
          return; // 桁あふれのため無視
        }
        _inputBuffer = candidate;
      }
    }
    notifyListeners();
  }

  void inputDot() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();

    if (_startsNewEntry) {
      _inputBuffer = '0.';
      _startsNewEntry = false;
    } else if (!_inputBuffer.contains('.')) {
      _inputBuffer = '$_inputBuffer.';
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 演算子・イコール
  // ---------------------------------------------------------------------

  void inputOperator(Operator op) {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();

    final current = _currentDecimal();
    final result = _engine.inputOperator(current, op);

    if (result.isError) {
      _setError();
      return;
    }

    _expressionLine =
        '${DisplayFormatter.format(result.value)} ${_operatorSymbol(op)}';
    _inputBuffer = result.value.toString();
    _startsNewEntry = true;
    notifyListeners();
  }

  void inputEquals() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();

    final current = _currentDecimal();
    final pendingOp = _engine.pendingOperator;
    final result = _engine.inputEquals(current);

    if (result.isError) {
      _setError();
      return;
    }

    if (pendingOp != Operator.none) {
      _expressionLine =
          '${DisplayFormatter.format(_engine.accumulator)} = ';
    }
    _gtManager.addResult(result.value);
    _inputBuffer = result.value.toString();
    _startsNewEntry = true;
    notifyListeners();
  }

  void inputPercent() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();

    final current = _currentDecimal();
    final result = _engine.inputPercent(current);

    if (result.isError) {
      _setError();
      return;
    }
    _inputBuffer = result.value.toString();
    _expressionLine = '$_expressionLine ${DisplayFormatter.format(current)}% =';
    _startsNewEntry = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // クリア系: C と AC の挙動を厳密に分離する
  // ---------------------------------------------------------------------

  /// [C]: 直前の入力値のみをクリアする。式・メモリ・GTは維持。
  void inputClearEntry() {
    if (_isError) {
      // エラー状態からの復帰も C で可能にする（実務上の利便性のため）
      _isError = false;
    }
    _inputBuffer = '0';
    _startsNewEntry = true;
    notifyListeners();
  }

  /// [AC]: 現在の計算状態を全クリアする。メモリ値は保持、GTはリセットする。
  void inputAllClear() {
    _engine.reset();
    _inputBuffer = '0';
    _expressionLine = '';
    _startsNewEntry = true;
    _isError = false;
    _gtManager.clear();
    // メモリ値は仕様により保持する（memoryManagerはクリアしない）
    notifyListeners();
  }

  void _setError() {
    _isError = true;
    _engine.reset();
    _inputBuffer = '0';
    _startsNewEntry = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // GT（グランドトータル）
  // ---------------------------------------------------------------------

  void inputGt() {
    if (_isError) return;
    final total = _gtManager.peekOrClear();
    _inputBuffer = total.toString();
    _startsNewEntry = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 独立4キーメモリ
  // ---------------------------------------------------------------------

  void inputMemoryPlus() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();
    _memoryManager.memoryPlus(_currentDecimal());
    _startsNewEntry = true;
    notifyListeners();
  }

  void inputMemoryMinus() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();
    _memoryManager.memoryMinus(_currentDecimal());
    _startsNewEntry = true;
    notifyListeners();
  }

  void inputMemoryRecall() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();
    _inputBuffer = _memoryManager.memoryRecall().toString();
    _startsNewEntry = true;
    notifyListeners();
  }

  void inputMemoryClear() {
    if (_isError) return;
    _gtManager.notifyOtherKeyPressed();
    _memoryManager.memoryClear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // テスト・デバッグ用アクセサ
  // ---------------------------------------------------------------------

  @visibleForTesting
  Decimal get debugMemory => _memoryManager.memory;

  @visibleForTesting
  Decimal get debugGt => _gtManager.total;

  @visibleForTesting
  String get debugInputBuffer => _inputBuffer;
}
