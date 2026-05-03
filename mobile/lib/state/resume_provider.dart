import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/resume.dart';
import '../services/storage.dart';

class ResumeProvider extends ChangeNotifier {
  ResumeProvider({required ResumeStorage storage, required ResumeData initial})
      : _storage = storage,
        _data = initial,
        _aiEnhanced = storage.getAiEnhanced(),
        _aiPaymentToken = storage.getAiPaymentToken();

  final ResumeStorage _storage;
  ResumeData _data;
  Timer? _saveDebounce;

  /// True after the resume has been rewritten by Gemini at least once. Goes
  /// false again when the user resets to the sample resume.
  bool _aiEnhanced;

  /// Server-issued payment token after a successful Google Play purchase
  /// for the current AI-enhanced resume. While set, the user can download
  /// the AI-enhanced PDF without paying again.
  String? _aiPaymentToken;

  ResumeData get data => _data;
  bool get aiEnhanced => _aiEnhanced;
  bool get hasPaidForAi => _aiPaymentToken != null && _aiPaymentToken!.isNotEmpty;
  String? get aiPaymentToken => _aiPaymentToken;

  /// Marks the current resume as AI-rewritten. Clears any prior payment
  /// token so the next download will require a fresh payment.
  void markAiEnhanced() {
    _aiEnhanced = true;
    _aiPaymentToken = null;
    _storage.setAiEnhanced(true);
    _storage.setAiPaymentToken(null);
    notifyListeners();
  }

  void setAiPaymentToken(String token) {
    _aiPaymentToken = token;
    _storage.setAiPaymentToken(token);
    notifyListeners();
  }

  void _persistDebounced() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      _storage.save(_data);
    });
  }

  void _bump() {
    notifyListeners();
    _persistDebounced();
  }

  // -- Personal info ---------------------------------------------------------

  void setPersonal({
    String? name,
    String? title,
    String? email,
    String? phone,
    String? location,
    String? linkedin,
    String? summary,
  }) {
    if (name != null) _data.name = name;
    if (title != null) _data.title = title;
    if (email != null) _data.email = email;
    if (phone != null) _data.phone = phone;
    if (location != null) _data.location = location;
    if (linkedin != null) _data.linkedin = linkedin;
    if (summary != null) _data.summary = summary;
    _bump();
  }

  // -- Skills / Languages ----------------------------------------------------

  void addSkill(String s) {
    final v = s.trim();
    if (v.isEmpty || _data.skills.contains(v)) return;
    _data.skills.add(v);
    _bump();
  }

  void removeSkill(int index) {
    _data.skills.removeAt(index);
    _bump();
  }

  void addLanguage(String s) {
    final v = s.trim();
    if (v.isEmpty || _data.languages.contains(v)) return;
    _data.languages.add(v);
    _bump();
  }

  void removeLanguage(int index) {
    _data.languages.removeAt(index);
    _bump();
  }

  // -- Experience ------------------------------------------------------------

  void addExperience() {
    _data.experience.add(Experience());
    _bump();
  }

  void updateExperience(String id, Experience updated) {
    final idx = _data.experience.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _data.experience[idx] = updated;
    _bump();
  }

  void removeExperience(String id) {
    _data.experience.removeWhere((e) => e.id == id);
    _bump();
  }

  // -- Education -------------------------------------------------------------

  void addEducation() {
    _data.education.add(Education());
    _bump();
  }

  void updateEducation(String id, Education updated) {
    final idx = _data.education.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _data.education[idx] = updated;
    _bump();
  }

  void removeEducation(String id) {
    _data.education.removeWhere((e) => e.id == id);
    _bump();
  }

  // -- Projects --------------------------------------------------------------

  void addProject() {
    _data.projects.add(Project());
    _bump();
  }

  void updateProject(String id, Project updated) {
    final idx = _data.projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _data.projects[idx] = updated;
    _bump();
  }

  void removeProject(String id) {
    _data.projects.removeWhere((p) => p.id == id);
    _bump();
  }

  // -- UI controls -----------------------------------------------------------

  void setTemplate(TemplateId t) {
    _data.template = t;
    _bump();
  }

  void setAccent(int color) {
    _data.accent = color;
    _bump();
  }

  // -- Bulk replace (used after AI improve) ---------------------------------

  void replaceAll(ResumeData next) {
    _data = next;
    _bump();
  }

  // -- Reset -----------------------------------------------------------------

  void resetToSample() {
    _data = ResumeData.sample();
    _aiEnhanced = false;
    _aiPaymentToken = null;
    _storage.setAiEnhanced(false);
    _storage.setAiPaymentToken(null);
    _bump();
  }

  // -- Score -----------------------------------------------------------------

  int computeScore() {
    int score = 0;
    if (_data.name.isNotEmpty) score += 5;
    if (_data.title.isNotEmpty) score += 5;
    if (_data.email.contains('@')) score += 5;
    if (_data.phone.isNotEmpty) score += 5;
    if (_data.location.isNotEmpty) score += 3;
    if (_data.linkedin.isNotEmpty) score += 2;
    if (_data.summary.length > 60) score += 10;
    score += (_data.skills.length * 2).clamp(0, 15);
    final expPoints = _data.experience.fold<int>(0, (acc, e) {
      var s = 0;
      if (e.role.isNotEmpty) s += 2;
      if (e.company.isNotEmpty) s += 2;
      if (e.duration.isNotEmpty) s += 1;
      if (e.description.length > 40) s += 5;
      return acc + s;
    });
    score += expPoints.clamp(0, 30);
    if (_data.education.isNotEmpty) score += 10;
    score += (_data.projects.length * 5).clamp(0, 10);
    return score.clamp(0, 100);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
