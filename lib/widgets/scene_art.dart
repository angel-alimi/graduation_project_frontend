import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import 'mascot.dart';

/// Shared pieces of the illustrated scenes (intro slides, login, sign-up).

const kSceneBg = Color(0xFFF6E2E7);
const kSceneInk = Color(0xFF1F2430);

const kFarSkyline =
    'M0 170V96h28V70h22v26h18V58h30v38h16V80h12l10-22 10 22h10v16h26V44h8v-8h6v8h8v52h20V74c0-16 26-16 26 0v22h22V62h34v34h18V84h22v12h24V66h26v104Z';
const kNearSkyline =
    'M0 120V70h34V48h26v22h20V36h14l4-10 4 10h14v34h24V58h30v12h14V30c0-20 36-20 36 0v40h20V52h28v18h22V44h30v26h22V60h48v60Z';

/// A skyline path tiled three times side by side (so edges never show).
/// Give it three times the visible width, starting one width to the left.
class Skyline extends StatelessWidget {
  const Skyline(this.path, this.viewHeight, this.fill, {super.key});
  final String path;
  final double viewHeight;
  final String fill;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-390 0 1170 $viewHeight" preserveAspectRatio="none">'
        '<g fill="$fill"><path transform="translate(-390 0)" d="$path"/><path d="$path"/>'
        '<path transform="translate(390 0)" d="$path"/></g></svg>',
        fit: BoxFit.fill,
      );
}

/// White, 85% opaque button used on top of the scenes.
class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.child, required this.onTap, this.radius = 12, this.tooltip});
  final Widget child;
  final VoidCallback onTap;
  final double radius;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: child),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => GlassButton(
        tooltip: context.tr('back'),
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, size: 20, color: kSceneInk),
        ),
      );
}

/// Full-width illustrated header for the login and sign-up screens:
/// pink sky behind the status bar, skyline, floating blood drops and the mascot,
/// with the back button (and optional step progress / trailing widget) on top.
/// Put it as the first child of a scroll view with no top padding.
class AuthHero extends StatefulWidget {
  const AuthHero({super.key, required this.pose, this.step, this.trailing});
  final MascotPose pose;

  /// Shows "Step n of 3" with progress bars next to the back button.
  final int? step;
  final Widget? trailing;

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero> with SingleTickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _float
        ..stop()
        ..value = 0;
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  double _bob(double phase) => -8 * (1 - math.cos(2 * math.pi * (_float.value + phase))) / 2;

  Widget _drop({double? left, double? right, required double top, required double size, required int color, required double phase}) =>
      Positioned(
        left: left,
        right: right,
        top: top,
        child: AnimatedBuilder(
          animation: _float,
          builder: (_, child) => Transform.translate(offset: Offset(0, _bob(phase)), child: child),
          child: Icon(Icons.water_drop_rounded, size: size, color: Color(color)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safeTop = mq.padding.top;
    final w = mq.size.width;
    final body = (mq.size.height * .3).clamp(210.0, 280.0);
    final h = safeTop + body;
    // Room between the top bar and the ground
    final mascot = math.min(140.0, (body - 84) / 1.07);

    return SizedBox(
      height: h,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: ColoredBox(
          color: kSceneBg,
          child: Stack(children: [
            Positioned(left: -w, width: w * 3, bottom: 30, height: 110, child: const Skyline(kFarSkyline, 170, '#EFD3DA')),
            Positioned(left: -w, width: w * 3, bottom: 0, height: 64, child: const Skyline(kNearSkyline, 120, '#E7BFC9')),
            _drop(left: w * .14, top: safeTop + 76, size: 14, color: 0xFFE79AA6, phase: 0),
            _drop(right: w * .13, top: safeTop + 66, size: 20, color: 0xFFDE7F90, phase: .35),
            _drop(right: w * .25, top: safeTop + 128, size: 11, color: 0xFFE9A9B3, phase: .7),
            // Mascot standing on the ground, with a soft shadow at its feet
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  width: mascot * .5,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0x2E781428),
                    borderRadius: BorderRadius.all(Radius.elliptical(mascot * .25, 5)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(offset: Offset(0, _bob(0) * .6), child: child),
                  child: Mascot(pose: widget.pose, size: mascot),
                ),
              ),
            ),
            // Top bar
            PositionedDirectional(
              top: safeTop + 8,
              start: 20,
              end: 20,
              child: Row(children: [
                const GlassBackButton(),
                const SizedBox(width: 12),
                Expanded(child: widget.step == null ? const SizedBox() : _StepBars(widget.step!)),
                if (widget.trailing != null) ...[const SizedBox(width: 12), widget.trailing!],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StepBars extends StatelessWidget {
  const _StepBars(this.step);
  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(context.tr('step', {'n': step}),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSceneInk)),
      const SizedBox(height: 6),
      Row(children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: i <= step ? 1 : 0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: .8),
                  color: AppColors.red,
                ),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 5),
        ],
      ]),
    ]);
  }
}
