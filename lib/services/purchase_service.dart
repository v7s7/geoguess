import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  static const String premiumProductId = 'all_flags_pack';
  static const String _premiumKey = 'is_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
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

  String get priceString {
    if (_product != null) return _product!.price;
    return '\$1.99';
  }

  PurchaseService() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    if (_isPremium) notifyListeners();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    await _loadProduct();
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

    // If store not available (e.g. simulator), grant premium for testing
    if (!_isAvailable || _product == null) {
      await _setPremium(true);
      _purchaseSuccess = true;
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
