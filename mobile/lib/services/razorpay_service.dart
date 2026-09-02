import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'api.dart';

/// Razorpay checkout (UPI / cards / net banking).
///
/// Flow:
///   1. [payAndVerify] asks the backend to create an order. The amount lives on
///      the server, so the price can't be tampered with from the app.
///   2. Razorpay Checkout opens with that order id.
///   3. On success Razorpay returns order id, payment id and a signature.
///   4. Those go back to the backend, which verifies the signature and returns
///      the same single-use payment token a Google Play purchase yields — so
///      the download-unlock path is identical for both providers.
///
/// The key secret never reaches the app; only the public key id does.
class RazorpayService {
  final ResumeApi _api;

  Razorpay? _razorpay;
  Completer<String>? _completer;
  void Function(String status)? _onStatus;

  RazorpayService(this._api);

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// Opens Razorpay Checkout and resolves with the server-issued payment token.
  /// Throws with a readable message if the user cancels or payment fails.
  Future<String> payAndVerify({
    required void Function(String status) onStatus,
  }) async {
    // Only one checkout at a time.
    if (_completer != null && !_completer!.isCompleted) {
      throw Exception('A payment is already in progress');
    }

    _onStatus = onStatus;
    onStatus('Creating order…');

    final order = await _api.createRazorpayOrder();
    final orderId = (order['orderId'] ?? '').toString();
    final keyId = (order['keyId'] ?? '').toString();
    if (orderId.isEmpty || keyId.isEmpty) {
      throw Exception('Server did not return a valid Razorpay order');
    }

    final completer = Completer<String>();
    _completer = completer;

    _razorpay?.clear();
    final razorpay = Razorpay();
    _razorpay = razorpay;
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    onStatus('Opening Razorpay…');
    try {
      razorpay.open({
        'key': keyId,
        'order_id': orderId,
        'amount': order['amount'],
        'currency': (order['currency'] ?? 'INR').toString(),
        'name': (order['companyName'] ?? 'AI Resume Builder').toString(),
        'description':
            (order['description'] ?? 'AI-enhanced resume download').toString(),
        'retry': {'enabled': true, 'max_count': 1},
      });
    } catch (e) {
      _finishWithError(Exception('Could not open Razorpay checkout: $e'));
    }

    try {
      return await completer.future;
    } finally {
      // Always detach listeners so a later checkout starts clean.
      razorpay.clear();
      if (identical(_razorpay, razorpay)) _razorpay = null;
      if (identical(_completer, completer)) _completer = null;
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      _finishWithError(
          Exception('Razorpay did not return the details needed to verify the payment'));
      return;
    }
    try {
      _onStatus?.call('Verifying payment…');
      final result = await _api.verifyRazorpayPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      final token = result['paymentToken'] as String?;
      if (token == null || token.isEmpty) {
        _finishWithError(Exception('Server did not return a payment token'));
        return;
      }
      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(token);
      }
    } catch (e) {
      // The money may have been taken but verification failed — say so clearly
      // rather than showing a generic failure.
      _finishWithError(Exception(
          'Payment succeeded but could not be verified. If you were charged, '
          'reopen the app to retry. ($e)'));
    }
  }

  void _onError(PaymentFailureResponse response) {
    // Razorpay reports user cancellation as an error code too; give it a
    // friendlier message than the raw payload.
    final raw = (response.message ?? '').trim();
    final cancelled = raw.toLowerCase().contains('cancel');
    _finishWithError(Exception(cancelled
        ? 'Payment cancelled'
        : (raw.isEmpty ? 'Payment failed' : raw)));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _onStatus?.call('Waiting for ${response.walletName ?? 'wallet'}…');
  }

  void _finishWithError(Object error) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(error);
    }
  }
}
