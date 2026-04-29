import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume.dart';

class ResumeStorage {
  static const _key = 'rb.resume.v1';

  final SharedPreferences _prefs;
  ResumeStorage(this._prefs);

  Future<ResumeData> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return ResumeData.sample();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ResumeData.fromJson(data);
    } catch (_) {
      return ResumeData.sample();
    }
  }

  Future<void> save(ResumeData data) async {
    await _prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<void> clear() => _prefs.remove(_key);
}
