import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/calculator_engine.dart';
import '../../state/calculator_controller.dart';
import 'calc_key.dart';

/// カシオ風5行×5列のキーパッド。
class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.read<CalculatorController>();

    Widget row(List<Widget> children) => Row(
          children: children
              .map(
                (w) => Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0, // 正方形固定
                    child: w,
                  ),
                ),
              )
              .toList(),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([
            CalcKey(
              label: 'MC',
              style: CalcKeyStyle.memoryKey,
              onTap: c.inputMemoryClear,
            ),
            CalcKey(
              label: 'MR',
              style: CalcKeyStyle.memoryKey,
              onTap: c.inputMemoryRecall,
            ),
            CalcKey(
              label: 'M-',
              style: CalcKeyStyle.memoryKey,
              onTap: c.inputMemoryMinus,
            ),
            CalcKey(
              label: 'M+',
              style: CalcKeyStyle.memoryKey,
              onTap: c.inputMemoryPlus,
            ),
            CalcKey(
              label: '÷',
              style: CalcKeyStyle.operatorKey,
              onTap: () => c.inputOperator(Operator.divide),
            ),
          ]),
          row([
            CalcKey(
              label: 'GT',
              style: CalcKeyStyle.functionKey,
              onTap: c.inputGt,
            ),
            CalcKey(label: '7', onTap: () => c.inputDigit('7')),
            CalcKey(label: '8', onTap: () => c.inputDigit('8')),
            CalcKey(label: '9', onTap: () => c.inputDigit('9')),
            CalcKey(
              label: '×',
              style: CalcKeyStyle.operatorKey,
              onTap: () => c.inputOperator(Operator.multiply),
            ),
          ]),
          row([
            CalcKey(
              label: '%',
              style: CalcKeyStyle.functionKey,
              onTap: c.inputPercent,
            ),
            CalcKey(label: '4', onTap: () => c.inputDigit('4')),
            CalcKey(label: '5', onTap: () => c.inputDigit('5')),
            CalcKey(label: '6', onTap: () => c.inputDigit('6')),
            CalcKey(
              label: '-',
              style: CalcKeyStyle.operatorKey,
              onTap: () => c.inputOperator(Operator.subtract),
            ),
          ]),
          row([
            CalcKey(
              label: 'C',
              style: CalcKeyStyle.functionKey,
              onTap: c.inputClearEntry,
            ),
            CalcKey(label: '1', onTap: () => c.inputDigit('1')),
            CalcKey(label: '2', onTap: () => c.inputDigit('2')),
            CalcKey(label: '3', onTap: () => c.inputDigit('3')),
            CalcKey(
              label: '+',
              style: CalcKeyStyle.operatorKey,
              onTap: () => c.inputOperator(Operator.add),
            ),
          ]),
          row([
            CalcKey(
              label: 'AC',
              style: CalcKeyStyle.functionKey,
              onTap: c.inputAllClear,
            ),
            CalcKey(label: '0', onTap: () => c.inputDigit('0')),
            CalcKey(label: '00', onTap: () => c.inputDigit('00')),
            CalcKey(label: '.', onTap: c.inputDot),
            CalcKey(
              label: '=',
              style: CalcKeyStyle.equalsKey,
              onTap: c.inputEquals,
            ),
          ]),
        ],
      ),
    );
  }
}