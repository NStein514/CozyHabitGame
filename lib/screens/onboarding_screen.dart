import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../theme/cozy_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});

  final GardenStore store;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _WelcomePage(
        emoji: '🌱',
        title: 'Small care grows beautiful things',
        body:
            'Turn everyday habits into a garden that becomes more alive with every check-in.',
      ),
      const _WelcomePage(
        emoji: '🦋',
        title: 'Progress without pressure',
        body:
            'There are no broken streak warnings here. Return gently, tend what you can, and keep growing.',
      ),
      _NamePage(controller: _nameController),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _page < 2
                    ? () => _controller.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      )
                    : null,
                child: Text(_page < 2 ? 'Skip' : ''),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? forest
                        : sage.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: FilledButton(
                onPressed: () {
                  if (_page < pages.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  } else {
                    widget.store.completeOnboarding(_nameController.text);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: forest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _page == pages.length - 1 ? 'Enter my garden' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.emoji,
    required this.title,
    required this.body,
  });
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 34),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 170,
          height: 170,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEBDD),
            shape: BoxShape.circle,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 82)),
        ),
        const SizedBox(height: 42),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 34),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🪴', style: TextStyle(fontSize: 78)),
        const SizedBox(height: 30),
        Text(
          'What should your garden call you?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'This stays only on your device.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 26),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Your name (optional)'),
        ),
      ],
    ),
  );
}
