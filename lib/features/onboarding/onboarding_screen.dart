import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_image.dart';

const _slides = [
  _Slide(
    image: 'assets/images/home1.jpg',
    tag: 'WELCOME TO ONLYMEN',
    title: 'Dress With\nIntent',
    subtitle: 'Premium men\'s fashion curated for those who understand that style is a statement, not an accident.',
  ),
  _Slide(
    image: 'assets/images/home2.jpg',
    tag: 'DISCOVER',
    title: 'Find Your\nSignature Look',
    subtitle: 'Browse curated collections, editorial lookbooks, and new arrivals — all crafted for the modern man.',
  ),
  _Slide(
    image: 'assets/images/home3.jpg',
    tag: 'EXPERIENCE',
    title: 'Style,\nDelivered',
    subtitle: 'Book a personal stylist, try on in store, or shop from anywhere. Your wardrobe, elevated.',
  ),
];

class _Slide {
  final String image;
  final String tag;
  final String title;
  final String subtitle;
  const _Slide({
    required this.image,
    required this.tag,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/home');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ONLYMEN',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _current == i ? 24 : 6,
                          height: 2,
                          color: _current == i
                              ? AppColors.accent
                              : AppColors.grey700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // CTA button
                    GestureDetector(
                      onTap: _finish,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        color: AppColors.accent,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GET STARTED',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: AppColors.black),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _current == _slides.length - 1
                                  ? Icons.arrow_forward
                                  : Icons.arrow_forward,
                              color: AppColors.black,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        AppImage(url: slide.image, fit: BoxFit.cover),

        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.black.withValues(alpha: 0.3),
                Colors.transparent,
                AppColors.black.withValues(alpha: 0.7),
                AppColors.black.withValues(alpha: 0.97),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: size.height * 0.22,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: AppColors.accent,
                child: Text(
                  slide.tag,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.black,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.title,
                style: AppTextStyles.display.copyWith(
                  color: AppColors.white,
                  fontSize: 48,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey300,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
