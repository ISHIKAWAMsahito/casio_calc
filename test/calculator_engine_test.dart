import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:casio_calc/logic/calculator_engine.dart';
import 'package:casio_calc/logic/gt_manager.dart';
import 'package:casio_calc/logic/memory_manager.dart';
import 'package:casio_calc/logic/display_formatter.dart';

void main() {
  group('CalculatorEngine - 浮動小数点誤差の排除', () {
    test('0.1 + 0.2 は厳密に 0.3 になる（IEEE754誤差を含まない）', () {
      final engine = CalculatorEngine();
      final a = Decimal.parse('0.1');
      final b = Decimal.parse('0.2');

      engine.inputOperator(a, Operator.add);
      final result = engine.inputEquals(b);

      expect(result.isError, isFalse);
      expect(result.value, Decimal.parse('0.3'));
      // 純粋なdoubleなら 0.1+0.2 = 0.30000000000000004 になり、
      // これがDecimal.parse('0.3')と一致しないことがバグの温床になる。
      expect(result.value.toString(), '0.3');
    });

    test('0.1 を3回加算しても厳密に 0.3 になる', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.parse('0.1'), Operator.add);
      engine.inputEquals(Decimal.parse('0.1'));
      engine.inputOperator(engine.accumulator, Operator.add);
      final result = engine.inputEquals(Decimal.parse('0.1'));
      expect(result.value, Decimal.parse('0.3'));
    });
  });

  group('CalculatorEngine - 逐次計算（チェーン計算）', () {
    test('1 + 2 × 3 = は (1+2)×3 = 9 になる（実機電卓の標準挙動）', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.fromInt(1), Operator.add);
      engine.inputOperator(Decimal.fromInt(2), Operator.multiply);
      final result = engine.inputEquals(Decimal.fromInt(3));

      expect(result.value, Decimal.fromInt(9));
    });

    test('連続イコール(=)で直前の演算を繰り返す', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.fromInt(5), Operator.add);
      final first = engine.inputEquals(Decimal.fromInt(3)); // 5+3=8
      expect(first.value, Decimal.fromInt(8));

      final second = engine.inputEquals(first.value); // 8+3=11
      expect(second.value, Decimal.fromInt(11));
    });

    test('ゼロ除算はエラーを返す', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.fromInt(10), Operator.divide);
      final result = engine.inputEquals(Decimal.zero);
      expect(result.isError, isTrue);
    });
  });

  group('CalculatorEngine - パーセント計算', () {
    test('1000 × 10% = 100（比率計算）', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.fromInt(1000), Operator.multiply);
      final result = engine.inputPercent(Decimal.fromInt(10));
      expect(result.value, Decimal.fromInt(100));
    });

    test('1000 + 10% = 1100（税込・割増計算）', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.fromInt(1000), Operator.add);
      final result = engine.inputPercent(Decimal.fromInt(10));
      expect(result.value, Decimal.fromInt(1100));
    });

    test('1000 - 10% = 900（割引計算）', () {
      final engine = CalculatorEngine();
      engine.inputOperator(Decimal.fromInt(1000), Operator.subtract);
      final result = engine.inputPercent(Decimal.fromInt(10));
      expect(result.value, Decimal.fromInt(900));
    });
  });

  group('CalculatorEngine - 12桁制限', () {
    test('12桁を超える結果はエラー(E)になる', () {
      final engine = CalculatorEngine();
      final big = Decimal.parse('999999999999'); // 12桁
      engine.inputOperator(big, Operator.add);
      final result = engine.inputEquals(Decimal.fromInt(1)); // 13桁になる
      expect(result.isError, isTrue);
    });
  });

  group('GtManager - グランドトータルのシナリオテスト', () {
    test('複数回の[=]確定結果がGTに積み上がる', () {
      final gt = GtManager();
      gt.addResult(Decimal.fromInt(100));
      gt.addResult(Decimal.fromInt(250));
      gt.addResult(Decimal.fromInt(50));

      expect(gt.total, Decimal.fromInt(400));
    });

    test('GT呼び出し(1回目)は値を返すだけでクリアしない', () {
      final gt = GtManager();
      gt.addResult(Decimal.fromInt(500));

      final peeked = gt.peekOrClear();
      expect(peeked, Decimal.fromInt(500));
      expect(gt.total, Decimal.fromInt(500)); // まだ消えていない
    });

    test('GTを2回連続で押すとクリアされる', () {
      final gt = GtManager();
      gt.addResult(Decimal.fromInt(500));

      gt.peekOrClear(); // 1回目: 呼び出し
      final secondPress = gt.peekOrClear(); // 2回目: クリア

      expect(secondPress, Decimal.zero);
      expect(gt.total, Decimal.zero);
    });

    test('GT以外のキー操作を挟むと連続押下カウントがリセットされる', () {
      final gt = GtManager();
      gt.addResult(Decimal.fromInt(300));

      gt.peekOrClear(); // 1回目
      gt.notifyOtherKeyPressed(); // 他のキー操作
      final result = gt.peekOrClear(); // これは「1回目」扱いになるはず

      expect(result, Decimal.fromInt(300)); // クリアされていない
    });

    test('AC相当のclear()でGTは即座に0になる', () {
      final gt = GtManager();
      gt.addResult(Decimal.fromInt(999));
      gt.clear();
      expect(gt.total, Decimal.zero);
    });
  });

  group('MemoryManager - 独立4キーメモリの動作テスト', () {
    test('M+ でメモリに加算される', () {
      final memory = MemoryManager();
      memory.memoryPlus(Decimal.fromInt(100));
      memory.memoryPlus(Decimal.fromInt(50));
      expect(memory.memory, Decimal.fromInt(150));
    });

    test('M- でメモリから減算される', () {
      final memory = MemoryManager();
      memory.memoryPlus(Decimal.fromInt(100));
      memory.memoryMinus(Decimal.fromInt(30));
      expect(memory.memory, Decimal.fromInt(70));
    });

    test('MR はメモリ値を変更せずに呼び出すだけ', () {
      final memory = MemoryManager();
      memory.memoryPlus(Decimal.fromInt(200));
      final recalled = memory.memoryRecall();

      expect(recalled, Decimal.fromInt(200));
      expect(memory.memory, Decimal.fromInt(200)); // 呼び出し後も変化なし
    });

    test('MC は1回の押下でメモリを即座にゼロクリアする', () {
      final memory = MemoryManager();
      memory.memoryPlus(Decimal.fromInt(999));
      expect(memory.hasMemory, isTrue);

      memory.memoryClear();
      expect(memory.hasMemory, isFalse);
      expect(memory.memory, Decimal.zero);
    });

    test('メモリが0でない間は hasMemory が true になる（Mインジケータ用）', () {
      final memory = MemoryManager();
      expect(memory.hasMemory, isFalse);

      memory.memoryPlus(Decimal.fromInt(1));
      expect(memory.hasMemory, isTrue);

      memory.memoryMinus(Decimal.fromInt(1));
      expect(memory.hasMemory, isFalse);
    });
  });

  group('DisplayFormatter - 3桁区切り表示', () {
    test('整数を3桁区切りでカンマ表示する', () {
      expect(DisplayFormatter.format(Decimal.parse('1234567')), '1,234,567');
    });

    test('小数部があっても整数部のみカンマ区切りされる', () {
      expect(DisplayFormatter.format(Decimal.parse('1234.5')), '1,234.5');
    });

    test('負の値は先頭にマイナス符号が付く', () {
      expect(DisplayFormatter.format(Decimal.parse('-1234')), '-1,234');
    });

    test('12桁超過の入力文字列を検出できる', () {
      expect(DisplayFormatter.exceedsMaxDigits('1234567890123'), isTrue); // 13桁
      expect(DisplayFormatter.exceedsMaxDigits('123456789012'), isFalse); // 12桁
    });
  });
}
