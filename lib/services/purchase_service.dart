import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 課金状態を配信するインターフェース。
abstract class PurchaseService extends ChangeNotifier {
  bool get isAdRemoved;

  /// 「広告を非表示にする」買い切り商品を購入する。
  Future<bool> purchaseRemoveAds();

  /// 購入の復元。
  Future<bool> restorePurchases();
}

/// `in_app_purchase` を利用する広告非表示商品の本番実装。
///
/// ストア側では [removeAdsProductId] を Non-Consumable として登録すること。
class InAppPurchaseService extends ChangeNotifier implements PurchaseService {
  InAppPurchaseService({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static const String removeAdsProductId = 'remove_ads';
  static const String _prefsKey = 'remove_ads_purchased';

  final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isAdRemoved = false;
  bool _initialized = false;
  bool _disposed = false;
  Completer<bool>? _purchaseCompleter;

  @override
  bool get isAdRemoved => _isAdRemoved;

  /// 保存済みの購入状態を直ちに反映し、その後のストア更新も監視する。
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isAdRemoved = prefs.getBool(_prefsKey) ?? false;
    _initialized = true;
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchaseUpdates(purchases)),
      onError: (_, __) => _completePendingPurchase(false),
      onDone: () => unawaited(_purchaseSubscription?.cancel() ?? Future<void>.value()),
    );
    notifyListeners();
  }

  @override
  Future<bool> purchaseRemoveAds() async {
    await initialize();
    if (_isAdRemoved || _purchaseCompleter != null) return _isAdRemoved;
    if (!await _inAppPurchase.isAvailable()) return false;

    final response = await _inAppPurchase.queryProductDetails(
      const <String>{removeAdsProductId},
    );
    if (response.error != null ||
        response.notFoundIDs.contains(removeAdsProductId)) {
      return false;
    }

    final product = response.productDetails.where(
      (details) => details.id == removeAdsProductId,
    );
    if (product.isEmpty) return false;

    final completer = Completer<bool>();
    _purchaseCompleter = completer;
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product.first),
    );
    if (!started) {
      _completePendingPurchase(false);
    }
    return completer.future;
  }

  @override
  Future<bool> restorePurchases() async {
    await initialize();
    if (!await _inAppPurchase.isAvailable()) return _isAdRemoved;

    try {
      await _inAppPurchase.restorePurchases();
    } catch (_) {
      return _isAdRemoved;
    }

    // 復元結果は purchaseStream で受信して永続化する。
    return _isAdRemoved;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        if (purchase.productID != removeAdsProductId) continue;

        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _grantRemoveAds();
            _completePendingPurchase(true);
            break;
          case PurchaseStatus.error:
          case PurchaseStatus.canceled:
            _completePendingPurchase(false);
            break;
          case PurchaseStatus.pending:
            break;
        }
      } finally {
        // ストアが要求する完了処理を必ず行う。未完了の取引を残さない。
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _grantRemoveAds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (!_disposed && !_isAdRemoved) {
      _isAdRemoved = true;
      notifyListeners();
    }
  }

  void _completePendingPurchase(bool result) {
    final completer = _purchaseCompleter;
    if (completer == null || completer.isCompleted) return;
    _purchaseCompleter = null;
    completer.complete(result);
  }

  @override
  void dispose() {
    _disposed = true;
    _completePendingPurchase(false);
    unawaited(_purchaseSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}

/// MVP用モック実装。
/// 実際のストア課金は行わず、ローカルフラグ (SharedPreferences) の
/// ON/OFF切り替えのみで「購入完了 → 広告非表示」の動作確認ができる。
class MockPurchaseService extends ChangeNotifier implements PurchaseService {
  static const _prefsKey = 'remove_ads_purchased';

  bool _isAdRemoved = false;
  bool _initialized = false;

  @override
  bool get isAdRemoved => _isAdRemoved;

  /// アプリ起動時に一度呼び出し、保存済みフラグを読み込む。
  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isAdRemoved = prefs.getBool(_prefsKey) ?? false;
    _initialized = true;
    notifyListeners();
  }

  @override
  Future<bool> purchaseRemoveAds() async {
    // TODO: 本番実装では in_app_purchase の buyNonConsumable() を呼び出す。
    // MVPではストア通信をシミュレートし、即座に成功として扱う。
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    _isAdRemoved = true;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    // TODO: 本番実装では in_app_purchase の restorePurchases() を呼び出し、
    // purchaseStream 経由で受け取ったレシートを検証する。
    final prefs = await SharedPreferences.getInstance();
    final restored = prefs.getBool(_prefsKey) ?? false;
    _isAdRemoved = restored;
    notifyListeners();
    return restored;
  }

  /// デバッグ・設定画面からの手動リセット用（QA目的）。
  Future<void> debugReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
    _isAdRemoved = false;
    notifyListeners();
  }
}
