import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The LifeShare blood-drop character, drawn from vector paths.
enum MascotPose { hero, wave, hug, phone }

class Mascot extends StatelessWidget {
  const Mascot({super.key, this.pose = MascotPose.hero, this.size = 120});

  final MascotPose pose;

  /// Width in logical pixels. Height follows the 224:240 ratio.
  final double size;

  static const _arm = '#b8132d';

  static const _body =
      '<ellipse cx="82" cy="226" rx="15" ry="7" fill="#7A0A1E"/><ellipse cx="118" cy="226" rx="15" ry="7" fill="#7A0A1E"/>'
      '<path d="M100 14C84 52 40 92 34 136c-8 54 26 88 66 88s74-34 66-88C160 92 116 52 100 14Z" fill="#cb1731"/>'
      '<path d="M34 136c-4 46 26 86 66 88 40 2 70-30 66-82-10 40-40 60-74 56-28-4-48-26-58-62Z" fill="#b0122b"/>'
      '<path d="M80 50C72 66 60 82 54 98" stroke="#ffffff" stroke-width="7" stroke-linecap="round" stroke-opacity="0.85" fill="none"/>'
      '<ellipse cx="80" cy="138" rx="12" ry="14" fill="#ffffff"/><ellipse cx="120" cy="138" rx="12" ry="14" fill="#ffffff"/>'
      '<circle cx="82" cy="141" r="7" fill="#2A0A12"/><circle cx="122" cy="141" r="7" fill="#2A0A12"/>'
      '<circle cx="85" cy="137" r="2.5" fill="#ffffff"/><circle cx="125" cy="137" r="2.5" fill="#ffffff"/>'
      '<ellipse cx="64" cy="162" rx="9" ry="5" fill="#FF8FA0" fill-opacity="0.7"/><ellipse cx="136" cy="162" rx="9" ry="5" fill="#FF8FA0" fill-opacity="0.7"/>'
      '<path d="M89 162Q100 174 111 162" stroke="#2A0A12" stroke-width="4" stroke-linecap="round" fill="none"/>';

  static String _back(MascotPose p) => p == MascotPose.hero
      ? '<path d="M70 110C40 130 30 180 18 216c32-8 48 0 66-12Z" fill="#6E0A1C"/>'
          '<path d="M130 110c30 20 42 72 54 106-32-8-50 0-68-12Z" fill="#8E0B22"/>'
      : '';

  static String _front(MascotPose p) {
    String arm(String d) => '<path d="$d" stroke="$_arm" stroke-width="11" stroke-linecap="round" fill="none"/>';
    String hand(num cx, num cy, num r) => '<circle cx="$cx" cy="$cy" r="$r" fill="$_arm"/>';
    switch (p) {
      case MascotPose.hero:
        return '<path d="M100 206c-8-6-13-10-13-15 0-4 3-7 7-7 3 0 5 2 6 4 1-2 3-4 6-4 4 0 7 3 7 7 0 5-5 9-13 15Z" fill="#ffffff"/>'
            '${arm('M40 160C26 166 24 182 38 188')}${hand(40, 188, 8)}'
            '${arm('M162 146c14-14 18-36 14-54')}${hand(176, 86, 10)}';
      case MascotPose.wave:
        return '${arm('M40 162c-10 10-6 24 6 28')}${hand(47, 190, 8)}'
            '${arm('M162 150c16-8 24-26 22-44')}${hand(184, 100, 10)}';
      case MascotPose.hug:
        return '<path d="M100 222c-20-13-31-22-31-34 0-9 7-15 15-15 7 0 12 4 16 9 4-5 9-9 16-9 8 0 15 6 15 15 0 12-11 21-31 34Z" fill="#ffffff" stroke="#F3C9D0" stroke-width="3"/>'
            '${arm('M40 160c8 16 20 30 32 32')}${hand(72, 192, 8)}'
            '${arm('M160 160c-8 16-20 30-32 32')}${hand(128, 192, 8)}';
      case MascotPose.phone:
        return '${arm('M40 162c-10 10-6 24 6 28')}${hand(47, 190, 8)}'
            '<rect x="148" y="112" width="40" height="66" rx="8" fill="#1F2430"/>'
            '<rect x="152" y="120" width="32" height="48" rx="4" fill="#ffffff"/>'
            '<path d="M168 130c-4 6-8 10-8 14a8 8 0 0 0 16 0c0-4-4-8-8-14z" fill="#cb1731"/>'
            '<circle cx="186" cy="114" r="7" fill="#F5A524" stroke="#ffffff" stroke-width="2.5"/>'
            '${arm('M162 154c-2 10-6 18-12 22')}${hand(152, 168, 9)}';
    }
  }

  static String svgFor(MascotPose p) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-12 0 224 240">${_back(p)}$_body${_front(p)}</svg>';

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(
        svgFor(pose),
        width: size,
        height: size * 240 / 224,
      ),
    );
  }
}
