import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../startup_logger.dart';

class PurchaseService extends ChangeNotifier {
  static const String premiumProductId = 'all_flags_pack';
  static const String _premiumKey = 'is_premium';

  // Lazy getter — InAppPurchase.instance is NEVER touched on Web,
  // which prevents the LateInitializationError thrown by the plugin.
  InAppPurchase get _iap => InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPremium = false;
  bool _isLoading = false;
  bool _isAvailable = false;
  ProductDetails? _product;
  String? _errorMessage;
  bool _purchaseSuccess = false;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  ProductDetails? get product => _product;
  String? get errorMessage => _errorMessage;
  bool get purchaseSuccess => _purchaseSuccess;

  String get priceString => _product?.price ?? '\$1.99';

  PurchaseService() {
    _initialize();
  }

  Future<void> _initialize() async {
    startupLog('purchase service init started');
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_premiumKey) ?? false;
      notifyListeners();

      // IAP plugin does not support Web — skip entirely to avoid
      // LateInitializationError from the platform channel setup.
      // iOS / Android follow the full flow below.
      if (kIsWeb) {
        startupLog('purchase service init skipped on web');
        return;
      }

      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        notifyListeners();
        startupLog('purchase service unavailable on this device');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
          startupLog('purchase stream error: $error');
        },
      );

      await _loadProduct();
      startupLog('purchase service init finished');
    } catch (e, stack) {
      _errorMessage = 'Store services are temporarily unavailable.';
      startupLog('purchase service init failed: $e');
      debugPrintStack(stackTrace: stack, label: '[GeoGuess][startup]');
      notifyListeners();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final response = await _iap.queryProductDetails({premiumProductId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> buyPremium() async {
    if (_isPremium) return;
    _purchaseSuccess = false;
    _errorMessage = null;

    // Web: no real store — grant premium so the UI stays functional.
    if (kIsWeb) {
      await _setPremium(true);
      _purchaseSuccess = true;
      notifyListeners();
      return;
    }

    // Store unavailable or product not loaded yet.
    // On a real device / TestFlight this only fires if App Store Connect
    // does not have the product configured — fix: create the in-app purchase
    // product "all_flags_pack" in App Store Connect and set it to "Ready to Submit".
    if (!_isAvailable || _product == null) {
      _errorMessage = _isAvailable
          ? 'Product not found. Please contact support.'
          : 'In-App Purchases are not available on this device.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: _product!);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (kIsWeb) return; // no-op on Web
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    await _iap.restorePurchases();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearPurchaseSuccess() {
    _purchaseSuccess = false;
    notifyListeners();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == premiumProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _setPremium(true);
          _purchaseSuccess = true;
        } else if (purchase.status == PurchaseStatus.error) {
          _errorMessage = purchase.error?.message ?? 'Purchase failed';
          _purchaseSuccess = false;
        }

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _iap.completePurchase(purchase);
        }
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
