import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 追加
import 'package:provider/provider.dart';

import 'services/purchase_service.dart';
import 'state/calculator_controller.dart';
import 'ui/calculator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob SDKの初期化
  await MobileAds.instance.initialize();

  // 縦画面固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final purchaseService = InAppPurchaseService();
  await purchaseService.initialize();

  runApp(CasioCalcApp(purchaseService: purchaseService));
}

class CasioCalcApp extends StatelessWidget {
  final PurchaseService purchaseService;

  const CasioCalcApp({super.key, required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CalculatorController>(
          create: (_) => CalculatorController(),
        ),
        ChangeNotifierProvider<PurchaseService>.value(
          value: purchaseService,
        ),
      ],
      child: MaterialApp(
        title: '実務電卓',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const CalculatorScreen(),
      ),
    );
  }
}
