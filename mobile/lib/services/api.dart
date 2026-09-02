import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/job.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'ApiException($status): $message';
}

class ResumeApi {
  /// Pass your backend's reachable HOST via --dart-define=API_BASE=...
  ///   • Android emulator + local backend: http://10.0.2.2:8080
  ///   • Real device + local backend:      http://<your-PC-LAN-IP>:8080
  ///   • Deployed (Railway, etc.):          https://your-app.up.railway.app
  /// The `/api/v1` prefix is added automatically, so it does not matter
  /// whether you include it in API_BASE or not.
  static const String _rawBaseUrl =
      String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8080');

  final String baseUrl;
  ResumeApi({String? baseUrl}) : baseUrl = _normalize(baseUrl ?? _rawBaseUrl);

  /// Strips a trailing slash and a trailing `/api/v1` so we can safely add the
  /// prefix ourselves. Makes API_BASE tolerant of both forms.
  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/api/v1')) {
      u = u.substring(0, u.length - '/api/v1'.length);
    }
    return u;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/v1$path'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return const {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['error'] is String) message = j['error'] as String;
    } catch (_) {
      if (res.body.isNotEmpty) message = res.body;
    }
    throw ApiException(res.statusCode, message);
  }

  /// Fire-and-forget analytics event. Never throws and never blocks the UI —
  /// failures (offline, etc.) are silently ignored.
  Future<void> logEvent(Map<String, dynamic> body) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/v1/events'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Analytics must never affect the app; swallow all errors.
    }
  }

  Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) {
    return _post('/payment/verify', {
      'productId': productId,
      'purchaseToken': purchaseToken,
    });
  }

  /// Asks the server to create a Razorpay order. The amount is decided
  /// server-side, so the client cannot influence the price. Returns the order
  /// id plus the public key id needed to open Razorpay Checkout.
  Future<Map<String, dynamic>> createRazorpayOrder() {
    return _post('/payment/razorpay/order', const {});
  }

  /// Sends the Razorpay Checkout result to the server, which verifies the
  /// signature and returns a payment token unlocking the download.
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    return _post('/payment/razorpay/verify', {
      'razorpayOrderId': orderId,
      'razorpayPaymentId': paymentId,
      'razorpaySignature': signature,
    });
  }

  Future<Map<String, dynamic>> parseResume({
    required String paymentToken,
    required String resumeText,
  }) {
    return _post('/resume/parse', {
      'paymentToken': paymentToken,
      'resumeText': resumeText,
    });
  }

  Future<List<JobMatch>> matchJobs({
    required List<String> skills,
    String? title,
    String? location,
    int limit = 12,
  }) async {
    final body = <String, dynamic>{
      'skills': skills,
      if (title != null && title.isNotEmpty) 'title': title,
      if (location != null && location.isNotEmpty) 'location': location,
      'limit': limit,
    };
    final res = await _post('/jobs/match', body);
    final list = (res['matches'] as List?) ?? const [];
    return list
        .map((e) => JobMatch.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> draftCoverLetter({
    required String name,
    required String title,
    required String summary,
    required List<String> skills,
    required String jobTitle,
    required String company,
    required String jobDescription,
  }) async {
    final res = await _post('/jobs/cover-letter', {
      'name': name,
      'title': title,
      'summary': summary,
      'skills': skills,
      'jobTitle': jobTitle,
      'company': company,
      'jobDescription': jobDescription,
    });
    return (res['coverLetter'] ?? '').toString();
  }
}
