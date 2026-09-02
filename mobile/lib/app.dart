import 'package:flutter/material.dart';

import 'screens/builder_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage.dart';
import 'theme.dart';

class ResumeBuilderApp extends StatefulWidget {
  final ResumeStorage storage;
  final bool showOnboarding;

  const ResumeBuilderApp({
    super.key,
    required this.storage,
    required this.showOnboarding,
  });

  @override
  State<ResumeBuilderApp> createState() => _ResumeBuilderAppState();
}

class _ResumeBuilderAppState extends State<ResumeBuilderApp> {
  late bool _onboarding = widget.showOnboarding;

  Future<void> _finishOnboarding() async {
    await widget.storage.setOnboardingDone(true);
    if (mounted) setState(() => _onboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _onboarding
          ? OnboardingScreen(onFinish: _finishOnboarding)
          : const BuilderScreen(),
    );
  }
}
