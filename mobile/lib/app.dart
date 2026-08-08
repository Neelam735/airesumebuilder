import 'package:flutter/material.dart';

import 'screens/builder_screen.dart';
import 'theme.dart';

class ResumeBuilderApp extends StatelessWidget {
  const ResumeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Resume Maker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const BuilderScreen(),
    );
  }
}
