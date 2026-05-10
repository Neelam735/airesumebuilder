import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'api.dart';

/// Wrapper around Google Play in-app billing.
///
/// Flow:
///   1. [load] queries the Play Store for the configured consumable product.
///   2. [purchaseAndVerify] launches Play's checkout for that product.
///   3. The purchase stream yields a [PurchaseDetails] with status PURCHASED.
///   4. We post the purchaseToken to the backend, which verifies it via the
///      Google Play Developer API and returns a single-use payment token.
///   5. The product is consumed (autoConsume on Android), so it can be
///      purchased again the next time the user wants AI improvement.
class BillingService {
  /// Must match the consumable in-app product configured in Play Console.
  static const String productId = String.fromEnvironment(
    'GOOGLE_PLAY_PRODUCT_ID',
    defaultValue: 'ai_resume_improvement',
  );

  final InAppPurchase _iap = InAppPurchase.instance;
  final ResumeApi _api;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  BillingService(this._api);

  ProductDetails? get product => _product;

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  /// Query Play for the consumable product. Returns true if the product is
  /// listed and ready.
  Future<bool> load() async {
    if (!await _iap.isAvailable()) return false;
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) return false;
    _product = response.productDetails.first;
    return true;
  }

  /// Launch the Play checkout sheet and resolve when the purchase reaches a
  /// terminal state. [onStatus] receives short progress strings for the UI.
  /// Returns the server-issued payment token that unlocks /resume/parse.
  Future<String> purchaseAndVerify({
    required void Function(String status) onStatus,
  }) async {
    if (_product == null) {
      final ok = await load();
      if (!ok || _product == null) {
        throw Exception(
          'Product "$productId" is not available on Play. Verify it is '
          'active in Play Console and your test account has access.',
        );
      }
    }

    final completer = Completer<String>();
    await _sub?.cancel();
    _sub = _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.productID != productId) continue;
        switch (p.status) {
          case PurchaseStatus.pending:
            onStatus('Awaiting Google Play…');
            break;
          case PurchaseStatus.canceled:
            await _completeIfPossible(p);
            if (!completer.isCompleted) {
              completer.completeError(Exception('Purchase canceled'));
            }
            break;
          case PurchaseStatus.error:
            await _completeIfPossible(p);
            if (!completer.isCompleted) {
              completer.completeError(
                Exception(p.error?.message ?? 'Purchase failed'),
              );
            }
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            try {
              onStatus('Verifying with server…');
              final token = p.verificationData.serverVerificationData;
              final result = await _api.verifyPurchase(
                productId: productId,
                purchaseToken: token,
              );
              final paymentToken = result['paymentToken'] as String?;
              if (paymentToken == null || paymentToken.isEmpty) {
                throw Exception('Server did not return a payment token');
              }
              await _completeIfPossible(p);
              if (!completer.isCompleted) completer.complete(paymentToken);
            } catch (e) {
              await _completeIfPossible(p);
              if (!completer.isCompleted) completer.completeError(e);
            }
            break;
        }
      }
    });

    onStatus('Opening Google Play…');
    final ok = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: _product!),
      autoConsume: true,
    );
    if (!ok) throw Exception('Could not launch Google Play checkout');

    return completer.future;
  }

  Future<void> _completeIfPossible(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(p);
      } catch (_) {}
    }
  }
}
