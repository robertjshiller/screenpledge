// lib/core/data/datasources/revenuecat_remote_datasource.dart
//
// PURPOSE
// -------
// Clean-architecture friendly wrapper around the RevenueCat purchases_flutter SDK.
// ViewModels talk ONLY to this class via the Riverpod provider.
//
// UPDATED FOR purchases_flutter v9.x
// ---------------------------------
// • Fixed breaking changes from the SDK update.
// • Configuration now uses the constructor for all parameters.
// • purchasePackage() now correctly handles the `PurchaseResult` object.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatRemoteDataSource {
  RevenueCatRemoteDataSource({
    required this.androidPublicApiKey,
    required this.iosPublicApiKey,
    this.defaultOfferingId = 'default',
    this.enableDebugLogs = true,
  });

  final String androidPublicApiKey;
  final String iosPublicApiKey;
  final String defaultOfferingId;
  final bool enableDebugLogs;

  bool _configured = false;
  Future<void>? _configureInFlight;

  final _customerInfoCtrl = StreamController<CustomerInfo>.broadcast();
  Stream<CustomerInfo> get customerInfoStream => _customerInfoCtrl.stream;

  /// One-time SDK initialization
  Future<void> configure() async {
    if (_configured) return;
    if (_configureInFlight != null) {
      await _configureInFlight;
      return;
    }
    _configureInFlight = _configureInternal();
    await _configureInFlight;
  }

  Future<void> _configureInternal() async {
    try {
      if (enableDebugLogs) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final key = Platform.isAndroid ? androidPublicApiKey : iosPublicApiKey;

      // ✅ FIXED: Breaking Change 1
      // In purchases_flutter v9+, `appUserID` and `observerMode` are now named
      // parameters in the PurchasesConfiguration constructor, not setters.
      final config = PurchasesConfiguration(key)
        ..appUserID = null; // appUserID can still be set this way if needed.
        // The observerMode is now a parameter on the configure method itself if needed,
        // but for most apps, you don't need to set it explicitly.
        // By default, it's false, which is what we want.

      // The configure method now just takes the configuration object.
      await Purchases.configure(config);
      _configured = true;

      try {
        final info = await Purchases.getCustomerInfo();
        _customerInfoCtrl.add(info);
        if (kDebugMode) {
          debugPrint('[RC] configured. originalAppUserId=${info.originalAppUserId}');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[RC] initial getCustomerInfo() failed: $e');
      }

      Purchases.addCustomerInfoUpdateListener((info) {
        _customerInfoCtrl.add(info);
        if (kDebugMode) {
          debugPrint('[RC] CustomerInfo updated. active entitlements=${info.entitlements.active.keys.toList()}');
        }
      });
    } finally {
      _configureInFlight = null;
    }
  }

  /// Fetch Offerings from RC dashboard
  Future<Offerings> fetchOfferings() async {
    assert(_configured, 'configure() must be called before fetchOfferings().');
    final offerings = await Purchases.getOfferings();
    if (kDebugMode) {
      final cur = offerings.current;
      debugPrint('[RC] Offerings fetched. current=${cur?.identifier} '
          'monthly=${cur?.monthly?.identifier} '
          'annual=${cur?.annual?.identifier}');
    }
    return offerings;
  }

  Package? getMonthly(Offerings o) => o.current?.monthly;
  Package? getAnnual(Offerings o) => o.current?.annual;

  Future<bool> hasPremium() async {
    assert(_configured, 'configure() must be called before hasPremium().');
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey('premium_access');
  }

  /// New: Wrap purchasePackage so ViewModels don't import Purchases
  Future<CustomerInfo> purchasePackage(Package package) async {
    assert(_configured, 'configure() must be called before purchasePackage().');

    // ✅ FIXED: Breaking Change 2
    // `Purchases.purchasePackage` no longer returns `CustomerInfo` directly.
    // It now returns a `PurchaseResult` object which contains the `CustomerInfo`.
    final PurchaseResult result = await Purchases.purchasePackage(package);

    // We extract the customerInfo from the result to maintain our method's signature.
    final CustomerInfo info = result.customerInfo;

    _customerInfoCtrl.add(info);
    return info;
  }

  Future<CustomerInfo> logIn(String appUserId) async {
    assert(_configured, 'configure() must be called before logIn().');
    final LogInResult result = await Purchases.logIn(appUserId);
    final CustomerInfo info = result.customerInfo;
    _customerInfoCtrl.add(info);
    if (kDebugMode) {
      debugPrint('[RC] logIn() -> created=${result.created}, appUserId=$appUserId, '
          'active entitlements=${info.entitlements.active.keys.toList()}');
    }
    return info;
  }

  Future<CustomerInfo> restorePurchases() async {
    assert(_configured, 'configure() must be called before restorePurchases().');
    final info = await Purchases.restorePurchases();
    _customerInfoCtrl.add(info);
    return info;
  }

  Future<String?> getCurrentAppUserId() async {
    assert(_configured, 'configure() must be called before getCurrentAppUserId().');
    try {
      final info = await Purchases.getCustomerInfo();
      return info.originalAppUserId;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _customerInfoCtrl.close();
  }
}

// ------------------
// RIVERPOD PROVIDER
// ------------------
final revenueCatRemoteDataSourceProvider = Provider<RevenueCatRemoteDataSource>((ref) {
  return RevenueCatRemoteDataSource(
    androidPublicApiKey: 'YOUR_ANDROID_PUBLIC_KEY',
    iosPublicApiKey: 'YOUR_IOS_PUBLIC_KEY',
  );
});