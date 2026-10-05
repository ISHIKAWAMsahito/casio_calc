import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/purchase_service.dart';

/// 歯車アイコンから開く設定ダイアログ。
/// 「広告を非表示にする」買い切り購入 と「購入の復元」を提供する。
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();

    return AlertDialog(
      title: const Text('設定'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              purchaseService.isAdRemoved
                  ? Icons.check_circle
                  : Icons.block,
              color: purchaseService.isAdRemoved ? Colors.green : Colors.grey,
            ),
            title: Text(
              purchaseService.isAdRemoved ? '広告は非表示です' : '広告を非表示にする',
            ),
            subtitle: purchaseService.isAdRemoved
                ? const Text('購入済み')
                : const Text('買い切り（一度の購入で永久に広告を非表示）'),
            onTap: purchaseService.isAdRemoved
                ? null
                : () async {
                    final ok = await purchaseService.purchaseRemoveAds();
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('購入が完了しました')),
                      );
                    }
                  },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('購入の復元'),
            onTap: () async {
              final restored = await purchaseService.restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(restored ? '購入情報を復元しました' : '復元できる購入情報がありません'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
