import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import '../widgets/scene_art.dart';
import 'auth/signup_info_screen.dart';

// Every scene is drawn in a fixed 390x525 box, then scaled to the screen.
const _boxW = 390.0;
const _boxH = 525.0;
const _shadow = Color(0x1F781428);

/// Three get-started slides: be a hero, request blood, donate nearby.
/// Each slide is an illustrated scene with depth layers that move at different
/// speeds while swiping (parallax).
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
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupInfoScreen()));
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
    final mq = MediaQuery.of(context);
    final last = _page == _count - 1;

    Widget slide(int i, Widget scene) => _Slide(
          index: i,
          controller: _pc,
          active: _page == i,
          scene: scene,
          a: 'ob${i + 1}a',
          b: 'ob${i + 1}b',
          c: 'ob${i + 1}c',
          body: 'ob${i + 1}p',
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(children: [
          Column(children: [
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  slide(0, _HeroScene(active: _page == 0)),
                  slide(1, _RequestScene(active: _page == 1)),
                  slide(2, _NearbyScene(active: _page == 2)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 30 + mq.padding.bottom),
              child: Row(children: [
                for (var i = 0; i < _count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    width: i == _page ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.red : AppColors.field,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                const Spacer(),
                _NextButton(wide: last, label: context.tr('createAccount'), onPressed: _next),
              ]),
            ),
          ]),

          // Back + Skip float on top of the scene
          PositionedDirectional(
            top: math.max(52, mq.padding.top + 8),
            start: 20,
            end: 20,
            child: Row(children: [
              const GlassBackButton(),
              const Spacer(),
              IgnorePointer(
                ignoring: last,
                child: AnimatedOpacity(
                  opacity: last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: GlassButton(
                    radius: 16,
                    onTap: () => _pc.animateToPage(_count - 1,
                        duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(context.tr('skip'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2430))),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide shell: scene on top, title + body below

class _Slide extends StatelessWidget {
  const _Slide({
    required this.index,
    required this.controller,
    required this.active,
    required this.scene,
    required this.a,
    required this.b,
    required this.c,
    required this.body,
  });
  final int index;
  final PageController controller;
  final bool active;
  final Widget scene;
  final String a, b, c, body;

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);
    final still = MediaQuery.of(context).disableAnimations;
    final dur = still ? Duration.zero : const Duration(milliseconds: 500);
    return LayoutBuilder(builder: (context, box) {
      // The scene takes everything above a fixed text area, so tall phones
      // get a taller picture instead of empty space under the text.
      final sceneHeight = math.max(box.maxHeight * .6, box.maxHeight - 190);
      // Tall scene: fill its height, cropping at most 12% off the sides.
      // Short scene: fit the height (extended backgrounds fill the sides).
      final sw = box.maxWidth / _boxW, sh = sceneHeight / _boxH;
      final scale = sh >= sw ? math.min(sh, sw * 1.12) : sh;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: sceneHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
          child: ColoredBox(
            color: kSceneBg,
            child: _ParallaxScope(
              controller: controller,
              index: index,
              rtl: dir == TextDirection.rtl,
              textDirection: dir,
              // Drawings never mirror; texts inside get the real direction back.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _boxW * scale,
                    height: _boxH * scale,
                    child: FittedBox(child: SizedBox(width: _boxW, height: _boxH, child: scene)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: dur,
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: dur,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, active ? 0 : 10, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: context.tr(a)),
                    TextSpan(text: context.tr(b), style: TextStyle(color: AppColors.red)),
                    TextSpan(text: context.tr(c)),
                  ]),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Text(context.tr(body), style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.muted)),
              ]),
            ),
          ),
        ),
      ),
    ]);
    });
  }
}

// ---------------------------------------------------------------------------
// Parallax

class _ParallaxScope extends InheritedWidget {
  const _ParallaxScope({
    required this.controller,
    required this.index,
    required this.rtl,
    required this.textDirection,
    required super.child,
  });
  final PageController controller;
  final int index;
  final bool rtl;

  /// The app's real direction, for texts inside the (always LTR) scene.
  final TextDirection textDirection;

  static _ParallaxScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ParallaxScope>()!;

  /// Distance in pages from this slide (0 = settled on it).
  double get delta {
    final c = controller;
    if (!c.hasClients || !c.position.haveDimensions) return 0;
    return (c.page ?? index.toDouble()) - index;
  }

  @override
  bool updateShouldNotify(_ParallaxScope old) =>
      old.controller != controller || old.index != index || old.rtl != rtl || old.textDirection != textDirection;
}

/// Shifts its child sideways while swiping: far = 1, mid = 2, near = 3.
class _ParallaxLayer extends StatelessWidget {
  const _ParallaxLayer({required this.depth, required this.child});
  final int depth;
  final Widget child;

  static const _shift = [0.0, 40.0, 90.0, 150.0];

  @override
  Widget build(BuildContext context) {
    final s = _ParallaxScope.of(context);
    return AnimatedBuilder(
      animation: s.controller,
      child: child,
      builder: (_, child) => Transform.translate(
        offset: Offset(-s.delta * _shift[depth] * (s.rtl ? -1 : 1), 0),
        child: child,
      ),
    );
  }
}

/// Gives scene texts the app's real direction (the scene itself is LTR).
class _SceneDir extends StatelessWidget {
  const _SceneDir({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: _ParallaxScope.of(context).textDirection, child: child);
}

// ---------------------------------------------------------------------------
// Scene base: one-shot animations replay each time the slide becomes current,
// loops run only while it is current. Reduced motion shows the final state.

abstract class _Scene extends StatefulWidget {
  const _Scene({required this.active});
  final bool active;
}

abstract class _SceneState<T extends _Scene> extends State<T> with TickerProviderStateMixin {
  final _once = <AnimationController>[];
  final _loops = <AnimationController>[];
  bool _still = false;
  bool _ready = false;

  AnimationController once(int ms) {
    final c = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    _once.add(c);
    return c;
  }

  AnimationController looping(int ms) {
    final c = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    _loops.add(c);
    return c;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (!_ready || still != _still) {
      _ready = true;
      _still = still;
      _sync();
    }
  }

  @override
  void didUpdateWidget(T old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (_still) {
      for (final c in _once) {
        c.stop();
        c.value = 1;
      }
      for (final c in _loops) {
        c.stop();
        c.value = 0;
      }
    } else if (widget.active) {
      for (final c in _once) {
        c.forward(from: 0);
      }
      for (final c in _loops) {
        c
          ..value = 0
          ..repeat();
      }
    } else {
      for (final c in _loops) {
        c.stop();
      }
    }
  }

  @override
  void dispose() {
    for (final c in [..._once, ..._loops]) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Smooth 10px up-and-down float for a 0..1 loop value.
double _bob(double t, [double phase = 0]) => -10 * (1 - math.cos(2 * math.pi * (t + phase))) / 2;

// ---------------------------------------------------------------------------
// Slide 1: Be someone's hero

class _HeroScene extends _Scene {
  const _HeroScene({required super.active});
  @override
  State<_HeroScene> createState() => _HeroSceneState();
}

class _HeroSceneState extends _SceneState<_HeroScene> {
  late final AnimationController _beat, _float, _hearts;

  @override
  void initState() {
    super.initState();
    _beat = once(2050);
    _float = looping(3600);
    _hearts = looping(4000);
  }

  Widget _drop(double left, double top, double size, int color, int depth, double phase) => Positioned(
        left: left,
        top: top,
        child: _ParallaxLayer(
          depth: depth,
          child: AnimatedBuilder(
            animation: _hearts,
            builder: (_, child) => Transform.translate(offset: Offset(0, _bob(_hearts.value, phase)), child: child),
            child: Icon(Icons.water_drop_rounded, size: size, color: Color(color)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: -_boxW,
        width: _boxW * 3,
        bottom: 46,
        height: 190,
        child: const _ParallaxLayer(depth: 1, child: Skyline(kFarSkyline, 170, '#EFD3DA')),
      ),
      Positioned(
        left: 0,
        width: _boxW,
        bottom: 132,
        height: 80,
        child: AnimatedBuilder(
          animation: _beat,
          builder: (_, __) => CustomPaint(
            painter: _HeartbeatPainter(
                const Interval(250 / 2050, 1, curve: Curves.easeOut).transform(_beat.value)),
          ),
        ),
      ),
      Positioned(
        left: -_boxW,
        width: _boxW * 3,
        bottom: 0,
        height: 120,
        child: const _ParallaxLayer(depth: 2, child: Skyline(kNearSkyline, 120, '#E7BFC9')),
      ),
      Positioned(
        left: (_boxW - 150) / 2,
        top: 142,
        child: _ParallaxLayer(
          depth: 3,
          child: AnimatedBuilder(
            animation: _float,
            builder: (_, child) => Transform.translate(offset: Offset(0, _bob(_float.value)), child: child),
            child: const Mascot(pose: MascotPose.hero, size: 150),
          ),
        ),
      ),
      _drop(58, 150, 16, 0xFFE79AA6, 2, 0),
      _drop(312, 126, 22, 0xFFDE7F90, 3, .35),
      _drop(292, 236, 12, 0xFFE9A9B3, 1, .7),
      Positioned(
        left: 0,
        right: 0,
        bottom: 22,
        child: _ParallaxLayer(
          depth: 3,
          child: Center(
            child: _ScenePill(
              icon: Icons.favorite_rounded,
              iconBg: AppColors.red,
              text: context.tr('s1chip'),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Heartbeat line that draws itself from left to right.
class _HeartbeatPainter extends CustomPainter {
  _HeartbeatPainter(this.progress);
  final double progress;

  static final _path = () {
    const pts = [
      Offset(0, 50), Offset(96, 50), Offset(106, 34), Offset(116, 50), Offset(138, 50),
      Offset(150, 10), Offset(164, 76), Offset(178, 26), Offset(188, 50), Offset(228, 50),
      Offset(236, 38), Offset(244, 50), Offset(390, 50),
    ];
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFFC0344C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.scale(size.width / 390, size.height / 80);
    // Flat line past both edges, for screens wider than the scene box.
    canvas.drawLine(const Offset(-400, 50), const Offset(0, 50), paint);
    for (final m in _path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
    if (progress >= 1) canvas.drawLine(const Offset(390, 50), const Offset(800, 50), paint);
  }

  @override
  bool shouldRepaint(_HeartbeatPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Slide 2: Request blood when needed

class _RequestScene extends _Scene {
  const _RequestScene({required super.active});
  @override
  State<_RequestScene> createState() => _RequestSceneState();
}

class _RequestSceneState extends _SceneState<_RequestScene> {
  late final AnimationController _pulse, _pulseIntro, _pop;

  // Types that can donate to B+.
  static const _donors = [
    (36.0, 198.0, 'O+'),
    (318.0, 178.0, 'B-'),
    (24.0, 346.0, 'O-'),
    (326.0, 328.0, 'B+'),
    (170.0, 438.0, 'O+'),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = looping(2400);
    _pulseIntro = once(1600);
    _pop = once(1700);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      // Pulse rings around the request
      Positioned(
        left: 195 - 150,
        top: 290 - 150,
        width: 300,
        height: 300,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _pulseIntro]),
          builder: (_, __) => Stack(children: [
            for (var i = 0; i < 3; i++)
              if (_pulseIntro.value * 1600 >= i * 800)
                Builder(builder: (_) {
                  final t = (_pulse.value - i / 3) % 1;
                  return Opacity(
                    opacity: .9 * (1 - t),
                    child: Transform.scale(
                      scale: .35 + .8 * t,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x59A71930), width: 1.5),
                        ),
                      ),
                    ),
                  );
                }),
          ]),
        ),
      ),

      // Matching donors pop in one after another
      for (var i = 0; i < _donors.length; i++)
        Positioned(
          left: _donors[i].$1,
          top: _donors[i].$2,
          child: _ParallaxLayer(
            depth: 2,
            child: AnimatedBuilder(
              animation: _pop,
              builder: (_, child) => Transform.scale(
                scale: Interval(i * 300 / 1700, (i * 300 + 500) / 1700, curve: Curves.easeOutBack)
                    .transform(_pop.value),
                child: child,
              ),
              child: _DonorBubble(_donors[i].$3),
            ),
          ),
        ),

      Positioned(
        left: 0,
        right: 0,
        top: 132,
        child: _ParallaxLayer(
          depth: 1,
          child: Center(
            child: _ScenePill(icon: Icons.check_rounded, iconBg: AppColors.green, text: context.tr('s2sent')),
          ),
        ),
      ),

      Positioned(
        left: (_boxW - 246) / 2,
        top: 194,
        width: 246,
        child: _ParallaxLayer(
          depth: 3,
          child: Transform.rotate(angle: -3 * math.pi / 180, child: const _RequestCardMock()),
        ),
      ),

      const Positioned(
        right: 18,
        bottom: -14,
        child: _ParallaxLayer(depth: 2, child: Mascot(pose: MascotPose.phone, size: 92)),
      ),
    ]);
  }
}

class _DonorBubble extends StatelessWidget {
  const _DonorBubble(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: AppFonts.latin, fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.red)),
      );
}

/// A blood request card built from the real app's pieces.
class _RequestCardMock extends StatelessWidget {
  const _RequestCardMock();

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 12, color: AppColors.muted);
    return _SceneDir(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x29781428), blurRadius: 40, offset: Offset(0, 18))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
              child: Text(context.tr('s2init'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.red)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('s2name'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(context.tr('s2meta'), style: muted),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(context.tr('s2needs'),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.local_hospital_outlined, size: 13, color: AppColors.muted),
            const SizedBox(width: 4),
            Flexible(child: Text(context.tr('s2hosp'), style: muted, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 10),
          Row(children: [
            const BloodLabel(BloodType.bPos, size: 13),
            const Spacer(),
            // Looks like the real SoftButton, but it's only a picture.
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: AppColors.surface,
                shape: StadiumBorder(side: BorderSide(color: AppColors.field, width: 1.2)),
              ),
              child: Text(context.tr('canDonate'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 3: Donate close to home

const _pinSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 46">'
    '<path d="M18 45s15-15.6 15-27A15 15 0 0 0 3 18c0 11.4 15 27 15 27z" fill="#A71930"/>'
    '<circle cx="18" cy="18" r="9" fill="#fff"/>'
    '<path d="M18 13v10M13 18h10" stroke="#A71930" stroke-width="3" stroke-linecap="round"/></svg>';

/// City map, extended well past the 390x525 box so scaling and parallax never show an edge.
/// Map coordinates sit 27px above box coordinates (box y = map y + 27).
final String _mapSvg = () {
  const cols = [[-394, 112], [-266, 112], [-138, 112], [-10, 112], [118, 164], [298, 110], [424, 112], [552, 112], [680, 112]];
  const rows = [[-356, 132], [-208, 132], [-60, 232], [188, 134], [338, 200], [554, 200], [770, 200]];
  const roadsX = [-274, -146, -18, 110, 290, 416, 544, 672];
  const roadsY = [-216, -68, 180, 330, 546, 762];
  final b = StringBuffer('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-400 -327 1190 1125">'
      '<rect x="-400" y="-327" width="1190" height="1125" fill="#F2E2E6"/><g fill="#EAD0D6">');
  for (final c in cols) {
    for (final r in rows) {
      if (c[0] == 118 && r[0] == 188) continue; // the park
      b.write('<rect x="${c[0]}" y="${r[0]}" width="${c[1]}" height="${r[1]}" rx="12"/>');
    }
  }
  b.write('</g><rect x="118" y="188" width="164" height="134" rx="12" fill="#E2EADD"/>'
      '<g fill="#CFDDC8"><circle cx="150" cy="222" r="11"/><circle cx="176" cy="290" r="9"/>'
      '<circle cx="246" cy="230" r="13"/><circle cx="214" cy="270" r="8"/></g><path d="');
  for (final x in roadsX) {
    b.write('M$x -400V900');
  }
  for (final y in roadsY) {
    b.write('M-500 ${y}H900');
  }
  b.write('" stroke="#FBF6F7" stroke-width="16" fill="none"/></svg>');
  return b.toString();
}();

class _NearbyScene extends _Scene {
  const _NearbyScene({required super.active});
  @override
  State<_NearbyScene> createState() => _NearbySceneState();
}

class _NearbySceneState extends _SceneState<_NearbyScene> {
  late final AnimationController _march, _drop;

  @override
  void initState() {
    super.initState();
    _march = looping(1200);
    _drop = once(900);
  }

  @override
  Widget build(BuildContext context) {
    const youSize = 86.0;
    const youH = youSize * 240 / 224;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: -400,
        top: -300,
        width: 1190,
        height: 1125,
        child: _ParallaxLayer(depth: 1, child: SvgPicture.string(_mapSvg, fit: BoxFit.fill)),
      ),
      Positioned.fill(
        child: _ParallaxLayer(
          depth: 1,
          child: AnimatedBuilder(
            animation: _march,
            builder: (_, __) => CustomPaint(painter: _RoutePainter(_march.value)),
          ),
        ),
      ),

      // You, standing at the start of the route
      Positioned(
        left: 66 + youSize / 2 - 27,
        top: 263 + youH - 8,
        child: _ParallaxLayer(
          depth: 3,
          child: Container(
            width: 54,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0x2E781428),
              borderRadius: BorderRadius.all(Radius.elliptical(27, 5)),
            ),
          ),
        ),
      ),
      const Positioned(
        left: 66,
        top: 263,
        child: _ParallaxLayer(depth: 3, child: Mascot(pose: MascotPose.wave, size: youSize)),
      ),

      // Hospital pin drops in at the end of the route
      Positioned(
        left: 272,
        top: 155,
        child: _ParallaxLayer(
          depth: 3,
          child: AnimatedBuilder(
            animation: _drop,
            builder: (_, child) {
              final v = _drop.value;
              final t = const Interval(200 / 900, 1, curve: Curves.easeOutBack).transform(v);
              final o = const Interval(200 / 900, 600 / 900).transform(v);
              return Opacity(
                opacity: o,
                child: Transform.translate(offset: Offset(0, -40 * (1 - t)), child: child),
              );
            },
            child: const _HospitalPin(),
          ),
        ),
      ),

      // "Request near you" notification
      Positioned(
        left: 20,
        right: 20,
        bottom: 22,
        child: _ParallaxLayer(
          depth: 2,
          child: _SceneDir(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: _shadow, blurRadius: 26, offset: Offset(0, 10))],
              ),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(8)),
                  child: const Text('A+',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          fontFamily: AppFonts.latin, fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr('mc2'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text(context.tr('mc2s'), style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _HospitalPin extends StatelessWidget {
  const _HospitalPin();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 46,
        child: Stack(clipBehavior: Clip.none, children: [
          Transform.translate(
            offset: const Offset(0, 6),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: SvgPicture.string(_pinSvg,
                  colorFilter: const ColorFilter.mode(Color(0x40781428), BlendMode.srcIn)),
            ),
          ),
          SvgPicture.string(_pinSvg),
        ]),
      );
}

/// Dotted route from you to the hospital, with the dots marching along it.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.t);
  final double t;

  static final _path = Path()
    ..moveTo(110, 357)
    ..lineTo(290, 357)
    ..lineTo(290, 207);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA71930)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const period = 11.0; // 1px dash + 10px gap
    final start = (22 * t) % period - period;
    for (final m in _path.computeMetrics()) {
      for (var d = start; d < m.length; d += period) {
        if (d + 1 <= 0) continue;
        canvas.drawPath(m.extractPath(math.max(0, d), d + 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Shared bits

/// White pill with a small coloured circle icon, used inside the scenes.
class _ScenePill extends StatelessWidget {
  const _ScenePill({required this.icon, required this.iconBg, required this.text});
  final IconData icon;
  final Color iconBg;
  final String text;

  @override
  Widget build(BuildContext context) => _SceneDir(
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [BoxShadow(color: _shadow, blurRadius: 22, offset: Offset(0, 8))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ]),
        ),
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
