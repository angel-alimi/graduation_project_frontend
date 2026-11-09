import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import 'auth/signup_info_screen.dart';

/// Three get-started slides: be a hero, request blood, donate nearby.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pc = PageController();
  int _page = 0;
  static const _count = 3;

  void _next() {
    if (_page == _count - 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupInfoScreen()));
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _count - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(children: [
            Row(children: [
              const BackSquareButton(),
              const Spacer(),
              AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: last
                      ? null
                      : () => _pc.animateToPage(_count - 1, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: Text(context.tr('skip'), style: const TextStyle(fontWeight: FontWeight.w400)),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide(
                    active: _page == 0,
                    art: const Mascot(pose: MascotPose.hero, size: 156),
                    a: 'ob1a', b: 'ob1b', c: 'ob1c', body: 'ob1p',
                  ),
                  _Slide(
                    active: _page == 1,
                    art: const Padding(padding: EdgeInsets.only(top: 12), child: Mascot(pose: MascotPose.phone, size: 150)),
                    overlay: PositionedDirectional(
                      top: 22,
                      start: 16,
                      child: _MiniCard(
                        leading: _typeBadge('A+'),
                        title: context.tr('mc1'),
                        subtitle: context.tr('mc1s'),
                      ),
                    ),
                    a: 'ob2a', b: 'ob2b', c: 'ob2c', body: 'ob2p',
                  ),
                  _Slide(
                    active: _page == 2,
                    art: const Mascot(pose: MascotPose.wave, size: 150),
                    overlay: PositionedDirectional(
                      bottom: 22,
                      end: 16,
                      child: _MiniCard(
                        leading: const IconBox(Icons.location_on_outlined, size: 30),
                        title: context.tr('mc2'),
                        subtitle: context.tr('mc2s'),
                      ),
                    ),
                    a: 'ob3a', b: 'ob3b', c: 'ob3c', body: 'ob3p',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(children: [
              Row(children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    width: i == _page ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.red : const Color(0xFFE0D3D6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ]),
              const Spacer(),
              _NextButton(wide: last, label: context.tr('createAccount'), onPressed: _next),
            ]),
          ]),
        ),
      ),
    );
  }

  static Widget _typeBadge(String t) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
      );
}

class _Slide extends StatelessWidget {
  const _Slide({required this.active, required this.art, required this.a, required this.b, required this.c, required this.body, this.overlay});
  final bool active;
  final Widget art;
  final Widget? overlay;
  final String a, b, c, body;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 210, height: 210, decoration: const BoxDecoration(color: Color(0x99FFFFFF), shape: BoxShape.circle)),
            AnimatedScale(
              scale: active ? 1 : .9,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(opacity: active ? 1 : .4, duration: const Duration(milliseconds: 500), child: art),
            ),
            if (overlay != null) overlay!,
          ]),
        ),
      ),
      const SizedBox(height: 26),
      Text.rich(
        TextSpan(children: [
          TextSpan(text: context.tr(a)),
          TextSpan(text: context.tr(b), style: const TextStyle(color: AppColors.red)),
          TextSpan(text: context.tr(c)),
        ]),
        style: tt.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(context.tr(body), style: tt.bodyMedium!.copyWith(color: AppColors.muted, height: 1.7)),
    ]);
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.leading, required this.title, required this.subtitle});
  final Widget leading;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x141F2430), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          leading,
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ]),
      );
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.wide, required this.label, required this.onPressed});
  final bool wide;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.red,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          height: 52,
          constraints: BoxConstraints(minWidth: wide ? 150 : 52),
          padding: EdgeInsets.symmetric(horizontal: wide ? 18 : 0),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (wide) ...[
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
            ],
            Semantics(label: context.tr('next'), child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)),
          ]),
        ),
      ),
    );
  }
}
