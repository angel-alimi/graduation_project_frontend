import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'auth/login_screen.dart';
import 'intro_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.app;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(children: [
            Row(children: [BrandRow(), Spacer(), LangPill()]),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset('assets/images/logo_drop.png', height: 128, semanticLabel: 'LifeShare'),
                  SizedBox(height: 20),
                  const Wordmark(fontSize: 34, spaced: true),
                  const SizedBox(height: 14),
                  Text(context.tr('tagline'),
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.muted)),
                ]),
              ),
            ),
            PrimaryButton(
              label: context.tr('getStarted'),
              height: 56,
              radius: 18,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IntroScreen())),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: TextButton.styleFrom(minimumSize: const Size(120, 48)),
              child: Text(context.tr('login'), style: const TextStyle(fontSize: 15)),
            ),
          ]),
        ),
      ),
    );
  }
}
