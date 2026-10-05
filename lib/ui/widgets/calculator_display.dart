import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/calculator_controller.dart';

/// 2行表示のディスプレイ部。
/// 上段: 計算式・履歴 + ステータス(GT / M)
/// 下段: 現在値・結果（長押しでコピー）
class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CalculatorController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上段: 式・履歴 + ステータスインジケータ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
              children: [
                if (controller.hasMemory)
                  const _StatusChip(
                    label: 'M',
                  ),
                if (controller.hasGt)
                  const _StatusChip(
                    label: 'GT',
                  ),
              ],
            ),
              Flexible(
                child: Text(
                  controller.expressionLine,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 下段: 現在値・結果
          GestureDetector(
            onLongPress: () async {
              await Clipboard.setData(
                  ClipboardData(text: controller.displayText));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('コピーしました'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              }
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                controller.displayText,
                style: TextStyle(
                  color: controller.isError ? Colors.redAccent : Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orangeAccent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
