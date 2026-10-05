import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// キーの役割ごとの見た目バリエーション。
enum CalcKeyStyle { numeral, operatorKey, memoryKey, functionKey, equalsKey }

/// カシオ実機風の単一キー。
class CalcKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final CalcKeyStyle style;

  const CalcKey({
    super.key,
    required this.label,
    required this.onTap,
    this.style = CalcKeyStyle.numeral,
  });

  Color _backgroundColor() {
    switch (style) {
      case CalcKeyStyle.numeral:
        return const Color(0xFF3A3A3C);
      case CalcKeyStyle.operatorKey:
        return const Color(0xFFFF9F0A);
      case CalcKeyStyle.memoryKey:
        return const Color(0xFF2C2C2E);
      case CalcKeyStyle.functionKey:
        return const Color(0xFF5B5B5D);
      case CalcKeyStyle.equalsKey:
        return const Color(0xFF34C759);
    }
  }

  Color _textColor() {
    return style == CalcKeyStyle.memoryKey
        ? Colors.orangeAccent
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Material(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: _textColor(),
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}