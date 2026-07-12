import 'package:easyedubd_app/features/presentation/screens/onboarding/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Learn Anytime, Anywhere',
      description:
          'Access high-quality video lectures made specifically for National '
          'University and 7 College students. Study whenever and wherever you want.',
      illustration: _LearnAnywhereIllustration(),
    ),
    _OnboardingPage(
      title: 'Everything You Need in One Place',
      description:
          'Access lectures, PDFs, suggestions, and organized study materials '
          'from a single learning platform.',
      illustration: _OnePlaceIllustration(),
    ),
    _OnboardingPage(
      title: 'Start Your Learning Journey',
      description:
          'Sign in to access your enrolled courses, continue your learning '
          'progress, and achieve academic success.',
      illustration: _JourneyIllustration(),
    ),
  ];

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await completeOnboarding();
    ref.invalidate(onboardingCompletedProvider);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Swipeable illustrations
            Expanded(
              flex: 5,
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: _pages.map((p) => p.illustration).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Animated title + description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: Column(
                    children: [
                      Text(
                        _pages[_index].title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _pages[_index].description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: active ? 26 : 9,
                  height: 9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: active ? primary : primary.withOpacity(0.25),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _goToPage(_index + 1);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final Widget illustration;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

/// ---- Illustration 1: Learn Anytime, Anywhere ----
class _LearnAnywhereIllustration extends StatelessWidget {
  const _LearnAnywhereIllustration();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.08),
            primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft background blobs
          Positioned(
            top: 30,
            left: 24,
            child: _blob(90, primary.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: _blob(70, primary.withOpacity(0.18)),
          ),

          // Laptop
          Positioned(
            bottom: 36,
            child: _deviceCard(
              width: 200,
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _miniLine(primary, width: 120),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniTile(primary),
                      _miniTile(primary),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Phone with video lecture
          Positioned(
            top: 40,
            child: _deviceCard(
              width: 110,
              height: 190,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: primary,
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 26,
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating icons
          Positioned(
            top: 70,
            left: 36,
            child: _floatingIcon(Icons.school, primary),
          ),
          Positioned(
            top: 150,
            right: 40,
            child: _floatingIcon(Icons.menu_book, primary),
          ),
          Positioned(
            bottom: 170,
            left: 50,
            child: _floatingIcon(Icons.cloud, primary),
          ),
        ],
      ),
    );
  }
}

/// ---- Illustration 2: Everything in One Place ----
class _OnePlaceIllustration extends StatelessWidget {
  const _OnePlaceIllustration();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final items = [
      ('Video Lectures', Icons.play_circle_fill),
      ('PDF Notes', Icons.picture_as_pdf),
      ('Exam Suggestions', Icons.lightbulb),
      ('Course Modules', Icons.view_module),
      ('Progress Tracking', Icons.show_chart),
      ('Study Materials', Icons.menu_book),
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.08),
            primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 24,
            right: 28,
            child: _blob(80, primary.withOpacity(0.14)),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items.map((item) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primary.withOpacity(0.12),
                        child: Icon(item.$2, color: primary, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---- Illustration 3: Start Your Learning Journey ----
class _JourneyIllustration extends StatelessWidget {
  const _JourneyIllustration();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.08),
            primary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 40,
            right: 30,
            child: _blob(90, primary.withOpacity(0.14)),
          ),
          Positioned(
            bottom: 30,
            left: 26,
            child: _blob(60, primary.withOpacity(0.18)),
          ),

          // Phone with app
          _deviceCard(
            width: 130,
            height: 220,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(10),
                  height: 34,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Easy Edu BD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.school,
                          color: primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating success icons
          Positioned(
            top: 70,
            left: 36,
            child: _floatingIcon(Icons.emoji_events, primary),
          ),
          Positioned(
            top: 150,
            right: 36,
            child: _floatingIcon(Icons.workspace_premium, primary),
          ),
          Positioned(
            bottom: 150,
            left: 44,
            child: _floatingIcon(Icons.check_circle, primary),
          ),
          Positioned(
            bottom: 90,
            right: 44,
            child: _floatingIcon(Icons.auto_graph, primary),
          ),
        ],
      ),
    );
  }
}

/// ---- Shared illustration helpers ----
Widget _blob(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

Widget _deviceCard({
  required double width,
  required double height,
  required Widget child,
}) =>
    Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

Widget _miniLine(Color color, {double width = 100}) => Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );

Widget _miniTile(Color color) => Container(
      width: 40,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
    );

Widget _floatingIcon(IconData icon, Color color) => CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white,
      child: Icon(icon, color: color, size: 22),
    );
