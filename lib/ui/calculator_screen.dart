import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_banner_wrapper.dart';
import '../services/purchase_service.dart';
import 'widgets/calculator_display.dart';
import 'widgets/calculator_keypad.dart';
import 'widgets/settings_dialog.dart';

/// 電卓画面本体（縦画面固定）。
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdRemoved = context.select<PurchaseService, bool>(
      (purchaseService) => purchaseService.isAdRemoved,
    );

    return Scaffold(
  backgroundColor: const Color(0xFF1C1C1E),
  body: SafeArea(
    child: Column(
      children: [

        // 1. ヘッダー: 設定アイコン
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
          child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 例: 現在の言語設定を参照して表示を分ける場合
Text(
  Localizations.localeOf(context).languageCode == 'ja'
      ? '実務電卓'
      : 'Business Calc',
  style: const TextStyle(color: Colors.white54, fontSize: 14),
),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () => SettingsDialog.show(context),
                  ),
                ],
              ),
            ),

            // 2. ディスプレイ部（余剰スペースをゆったり確保）
            const Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: CalculatorDisplay(),
              ),
            ),

            const SizedBox(height: 8),

            // 3. キーパッド部（正方形キーで画面下部に収まる）
            const CalculatorKeypad(),

            // 4. バナー広告（課金完了時は非表示）
            AdBannerWrapper(isAdRemoved: isAdRemoved),
          ],
        ),
      ),
    );
  }
}
