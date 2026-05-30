import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      backgroundColor: Color(0xFF1A535C),
      emoji: '🌍',
      title: 'Your world, mapped.',
      body: 'Every café, restaurant, hidden gem — pinned exactly where it happened.',
    ),
    _OnboardingPage(
      backgroundColor: Color(0xFF2C3E50),
      emoji: '📸',
      title: 'Memories, not just places.',
      body: 'Log photos, moods, and journal entries. Build a living scrapbook of your life.',
    ),
    _OnboardingPage(
      backgroundColor: Color(0xFFE74C3C),
      emoji: '👥',
      title: 'Explore with friends.',
      body: 'See where your crew has been. Find hidden gems through the people you trust.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<UserProvider>().completeOnboarding();
    // completeOnboarding triggers notifyListeners, which causes the Consumer
    // in MemoryMapApp to rebuild and show _AppShell automatically.
    // Pop all routes back to root so the Consumer can take over.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
          ),

          // Bottom overlay: dots + button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Next / Let's go button
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? "Let's go →"
                                : 'Next',
                            style: TextStyle(
                              color: _pages[_currentPage].backgroundColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

class _OnboardingPage {
  final Color backgroundColor;
  final String emoji;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.backgroundColor,
    required this.emoji,
    required this.title,
    required this.body,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: page.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                page.emoji,
                style: const TextStyle(fontSize: 100),
              ),
              const SizedBox(height: 40),
              Text(
                page.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              // Spacer to push content up and leave room for the bottom controls
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

