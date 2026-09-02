import 'package:flutter/material.dart';

import '../theme.dart';

/// First-run walkthrough shown to new users. A swipeable, animated set of
/// intro slides ending in a "Get Started" call to action. Shown once (gated by
/// ResumeStorage.onboardingDone).
class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  const _OnboardingSlide(this.icon, this.tint, this.title, this.body);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      Icons.edit_note_rounded,
      AppColors.brand,
      'Build in minutes',
      'A clean, guided editor for every section — no design skills needed.',
    ),
    _OnboardingSlide(
      Icons.auto_awesome_rounded,
      AppColors.warn,
      'Enhance with AI',
      'Let AI rewrite your resume in strong, professional language. Already '
          'have one? Upload a PDF or Word file and improve it instantly.',
    ),
    _OnboardingSlide(
      Icons.style_rounded,
      AppColors.accent,
      'Templates & live preview',
      'Pick a modern template and accent colour, and see exactly how your '
          'resume looks as you type.',
    ),
    _OnboardingSlide(
      Icons.file_download_done_rounded,
      AppColors.success,
      'Export anywhere',
      'Download your finished resume as a PDF or Word file — ready to send to '
          'recruiters or upload to job portals.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onFinish,
                child: Text(_isLast ? '' : 'Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, active: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              color: slide.tint.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: slide.tint.withOpacity(0.35), width: 2),
            ),
            child: Icon(slide.icon, size: 72, color: slide.tint),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, height: 1.5, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? AppColors.brand : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
