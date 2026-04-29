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
  /// Set this to your backend's reachable URL.
  /// On Android emulator, use http://10.0.2.2:8080 to reach localhost on host.
  /// On a real device, point this at your deployed server.
  static const String defaultBaseUrl =
      String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8080/api/v1');

  final String baseUrl;
  ResumeApi({this.baseUrl = defaultBaseUrl});

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
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

  Future<Map<String, dynamic>> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) {
    return _post('/payment/verify', {
      'productId': productId,
      'purchaseToken': purchaseToken,
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
