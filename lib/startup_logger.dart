import 'package:flutter/foundation.dart';

void startupLog(String message) {
  final timestamp = DateTime.now().toIso8601String();
  debugPrint('[GeoGuess][startup][$timestamp] $message');
}
