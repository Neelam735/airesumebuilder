import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/resume_provider.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = ResumeStorage(prefs);
  final initial = await storage.load();
  final onboardingDone = storage.getOnboardingDone();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ResumeProvider(storage: storage, initial: initial),
      child: ResumeBuilderApp(
        storage: storage,
        showOnboarding: !onboardingDone,
      ),
    ),
  );
}
