import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume.dart';

class ResumeStorage {
  static const _resumeKey = 'rb.resume.v1';
  static const _aiEnhancedKey = 'rb.aiEnhanced';
  static const _aiPaymentTokenKey = 'rb.aiPaymentToken';

  final SharedPreferences _prefs;
  ResumeStorage(this._prefs);

  Future<ResumeData> load() async {
    final raw = _prefs.getString(_resumeKey);
    if (raw == null) return ResumeData.sample();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ResumeData.fromJson(data);
    } catch (_) {
      return ResumeData.sample();
    }
  }

  Future<void> save(ResumeData data) async {
    await _prefs.setString(_resumeKey, jsonEncode(data.toJson()));
  }

  bool getAiEnhanced() => _prefs.getBool(_aiEnhancedKey) ?? false;

  Future<void> setAiEnhanced(bool v) => _prefs.setBool(_aiEnhancedKey, v);

  String? getAiPaymentToken() => _prefs.getString(_aiPaymentTokenKey);

  Future<void> setAiPaymentToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_aiPaymentTokenKey);
    } else {
      await _prefs.setString(_aiPaymentTokenKey, token);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_resumeKey);
    await _prefs.remove(_aiEnhancedKey);
    await _prefs.remove(_aiPaymentTokenKey);
  }
}
