import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/purchase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Configure flutter_animate defaults
  Animate.restartOnHotReload = true;
  // Lock to portrait for best mobile UX
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseService()),
      ],
      child: const GeoGuessApp(),
    ),
  );
}
