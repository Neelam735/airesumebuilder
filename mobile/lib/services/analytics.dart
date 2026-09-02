import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api.dart';

/// Lightweight, privacy-safe usage analytics. Logs an event to the local
/// console (debugPrint) and posts it to the backend `/events` endpoint so
/// actions (app open, enhance, download, payment, …) appear in the server logs.
///
/// It never sends resume content or personal data — only an event name and an
/// optional short, non-identifying detail. All calls are fire-and-forget.
class Analytics {
  final ResumeApi api;

  /// A random per-launch id so events from one session can be grouped, without
  /// identifying the user.
  final String sessionId;

  Analytics(this.api) : sessionId = _newSessionId();

  void log(String event, [String? detail]) {
    debugPrint('[event] $event${detail != null ? ' · $detail' : ''}');
    // Fire-and-forget; ResumeApi.logEvent swallows any error.
    api.logEvent({
      'event': event,
      if (detail != null) 'detail': detail,
      'sessionId': sessionId,
      'platform': _platform(),
    });
  }

  static String _platform() {
    try {
      return Platform.operatingSystem; // android / ios
    } catch (_) {
      return 'unknown';
    }
  }

  static String _newSessionId() {
    final r = Random();
    return List.generate(10, (_) => r.nextInt(36).toRadixString(36)).join();
  }
}
