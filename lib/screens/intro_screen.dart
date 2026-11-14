import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/onboarding_art.dart';
import 'auth/signup_info_screen.dart';

// The slides are always light: the illustrations are drawn on white.
const _bg = Colors.white;
const _ink = Color(0xFF1F2430);
const _body = Color(0xFF5F6672);
const _dotOff = Color(0xFFF2C9D0);

/// Three get-started slides: illustration, coloured title and a short text,
/// with page dots and a round Next button. Skip jumps to the last slide.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pc = PageController();
  int _page = 0;
  static const _count = 3;

  bool get _last => _page == _count - 1;

  void _next() {
    if (_last) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupInfoScreen()));
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  void _skip() =>
      _pc.animateToPage(_count - 1, duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(children: [
            // Top bar: back on the start side, Skip pill on the end side.
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  IconButton(
                    tooltip: app.t('back'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _last ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _last,
                      child: _Pill(label: app.t('skip'), onTap: _skip, small: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                ]),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _Slide(
                  index: i,
                  controller: _pc,
                  title: '${app.t('ob${i + 1}a')}${app.t('ob${i + 1}b')}${app.t('ob${i + 1}c')}'.trim(),
                  body: app.t('ob${i + 1}p'),
                ),
              ),
            ),
            // Dots on the start side, Next / Create account on the end side.
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 24, 20),
              child: SizedBox(
                height: 56,
                child: Row(children: [
                  for (var i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.red : _dotOff,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
                    child: _last
                        ? _Pill(key: const ValueKey('done'), label: app.t('createAccount'), onTap: _next)
                        : _RoundNext(key: const ValueKey('next'), tooltip: app.t('next'), onTap: _next),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.index, required this.controller, required this.title, required this.body});
  final int index;
  final PageController controller;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // 0 when this slide is centred, 1 when it is a full page away.
        var d = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          d = ((controller.page ?? 0) - index).abs().clamp(0.0, 1.0);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            Expanded(
              flex: 6,
              child: Transform.scale(
                scale: 1 - d * .12,
                child: Opacity(
                  opacity: 1 - d * .6,
                  child: Center(child: OnboardingArt(index)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: Opacity(
                opacity: (1 - d * 1.6).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 14 * d),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(children: [
                      Text(title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.red)),
                      const SizedBox(height: 12),
                      Text(body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.6, color: _body)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Solid red pill, used for Skip (small) and the final call to action.
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label, required this.onTap, this.small = false});
  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.red,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: small ? 34 : 52,
            padding: EdgeInsets.symmetric(horizontal: small ? 18 : 26),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(color: Colors.white, fontSize: small ? 13 : 15, fontWeight: FontWeight.w800)),
          ),
        ),
      );
}

/// Round red Next button with an arrow that points forward in both directions.
class _RoundNext extends StatelessWidget {
  const _RoundNext({super.key, required this.onTap, required this.tooltip});
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.red,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      );
}
