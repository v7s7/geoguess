import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — skipped gracefully if firebase_options.dart is not yet
  // configured. Run `flutterfire configure` to generate real options.
  try {
    // ignore: unused_import
    // ignore: avoid_dynamic_calls
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
  } catch (_) {}

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
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const GeoGuessApp(),
    ),
  );
}
