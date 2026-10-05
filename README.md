# 実務電卓アプリ（Casio Calc）- MVP

カシオ実機準拠キー配列 + 独立4キーメモリ + 厳密10進数計算を備えた、
簿記学習者・経理・小売実務者向けの電卓アプリ（Flutter / Dart）。

## ディレクトリ構成

```
casio_calc/
├── pubspec.yaml
├── lib/
│   ├── main.dart                        # エントリポイント / Provider配線
│   ├── logic/                           # 純粋Dart（単体テスト可能・Flutter非依存）
│   │   ├── calculator_engine.dart       # 四則演算・逐次計算・%計算・桁あふれ判定
│   │   ├── gt_manager.dart              # グランドトータル管理
│   │   ├── memory_manager.dart          # 独立4キーメモリ（MC/MR/M-/M+）
│   │   └── display_formatter.dart       # 3桁区切り表示・桁数チェック
│   ├── state/
│   │   └── calculator_controller.dart   # ChangeNotifier: UIと純粋ロジックを接続
│   ├── services/
│   │   ├── purchase_service.dart        # 課金インターフェース + モック実装
│   │   └── ad_banner_wrapper.dart       # バナー広告（購入済みなら描画破棄）
│   └── ui/
│       ├── calculator_screen.dart       # 画面全体レイアウト
│       └── widgets/
│           ├── calculator_display.dart  # 2行ディスプレイ（長押しコピー対応）
│           ├── calc_key.dart            # 触感フィードバック付き単一キー
│           ├── calculator_keypad.dart   # カシオ配列 5行×5列グリッド
│           └── settings_dialog.dart     # 広告非表示購入・購入の復元
└── test/
    └── calculator_engine_test.dart      # 浮動小数点誤差・GT・メモリの単体テスト
```

## セットアップ

```bash
flutter pub get
flutter run
```

## テスト実行

```bash
flutter test
```

`test/calculator_engine_test.dart` では以下を検証しています。

- **浮動小数点誤差の排除**: `0.1 + 0.2` が厳密に `0.3` になること（`decimal`パッケージによりIEEE754誤差を回避）
- **逐次計算**: `1 + 2 × 3 =` が実機同様 `(1+2)×3=9` になること、連続イコールの繰り返し計算
- **%計算**: 比率・割増・割引の3パターン
- **12桁制限**: 桁あふれ時に `E` エラーとなること
- **GT（グランドトータル）**: 複数回の`=`確定結果の積算、2回連続`GT`でのクリア、他キー操作を挟んだ場合のリセット
- **独立4キーメモリ**: `M+`/`M-`/`MR`/`MC` それぞれの独立した挙動、`M`インジケータの表示条件
- **表示フォーマット**: 3桁区切りカンマ表示

## 実装メモ・本番化に向けたTODO

1. **広告 (`ad_banner_wrapper.dart`)**: 現状はプレースホルダーの`Container`です。
   本番実装では `google_mobile_ads` パッケージを導入し、`BannerAd` + `AdWidget` に置き換えてください
   （`pubspec.yaml`にコメントアウトで依存を記載済み）。
2. **課金 (`purchase_service.dart`)**: `MockPurchaseService` はSharedPreferencesのフラグ切り替えのみで
   購入完了をシミュレートします。本番では `in_app_purchase` パッケージを用いた実装（レシート検証・
   `purchaseStream`監視・Non-Consumable商品ID登録）に差し替えてください。インターフェース
   (`PurchaseService`) は変更不要な設計にしています。
3. **AC時のGT仕様**: 仕様書に「GTはリセット/保持のいずれか」との記載があったため、MVPでは
   「ACでGTをリセットする」実装としています（`CalculatorController.inputAllClear`）。
   保持仕様に変更する場合は該当行の `_gtManager.clear()` を削除してください。
4. **符号切り替え(+/-)キー**: 現行のキー配列（カシオ標準10桁機準拠）には含まれていないため未実装です。
   必要であれば`calculator_keypad.dart`にキーを追加し、`CalculatorController`に
   `toggleSign()`を実装してください。
