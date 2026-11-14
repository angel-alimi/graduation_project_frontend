import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Flat illustrations for the get-started slides. They share the palette of
/// `assets/images/onboard_donate.jpg` (soft blue blob, teal clothes, green
/// leaves, faceless people) so the three slides look like one set.

const _skin = '#F2C4A8';
const _hair = '#3B2A30';
const _teal = '#5BB0C5';
const _pants = '#6E5263';
const _leaf = '#A3B56B';
const _leafLine = '#C3CF94';
const _blob = '#E4F3F8';
const _red = '#E5484D';
const _brand = '#A71930';

/// Big leaf at the bottom of a scene. [flip] mirrors it for the right side.
String _leaves(double x, double y, {bool flip = false}) {
  final s = flip ? -1 : 1;
  return '<g transform="translate($x $y) scale($s 1)">'
      '<path d="M0 0 C-10 -40 10 -78 46 -92 C52 -60 44 -20 0 0Z" fill="$_leaf"/>'
      '<path d="M2 -4 L40 -84" stroke="$_leafLine" stroke-width="3" stroke-linecap="round"/>'
      '<path d="M8 0 C30 -26 66 -38 96 -30 C82 -6 46 10 8 0Z" fill="$_leaf"/>'
      '<path d="M12 -2 L88 -28" stroke="$_leafLine" stroke-width="3" stroke-linecap="round"/>'
      '</g>';
}

/// Blood drop centred on (x, y), [r] is the round part's radius.
String _drop(double x, double y, double r, String fill) =>
    '<path transform="translate($x $y)" d="M0 ${-r * 1.9} C${r * .7} ${-r * .9} $r ${-r * .3} $r ${r * .1} '
    'A$r $r 0 0 1 ${-r} ${r * .1} C${-r} ${-r * .3} ${-r * .7} ${-r * .9} 0 ${-r * 1.9}Z" fill="$fill"/>';

/// Slide 2: a woman posting a blood request from her phone; matching donors
/// answer around it.
const String requestArtSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 340">
  <path d="M60 210 C40 120 110 40 210 44 C310 48 370 110 356 200 C344 278 270 312 190 306 C110 300 72 262 60 210Z" fill="$_blob"/>
  LEAVES_L
  LEAVES_R
  <ellipse cx="200" cy="306" rx="150" ry="8" fill="#DCEBF0"/>

  <!-- phone -->
  <rect x="206" y="52" width="122" height="236" rx="20" fill="#2F3A4A"/>
  <rect x="214" y="68" width="106" height="204" rx="12" fill="#FFFFFF"/>
  <rect x="252" y="58" width="30" height="5" rx="2.5" fill="#4A5566"/>
  <rect x="214" y="68" width="106" height="34" rx="12" fill="$_brand"/>
  <rect x="214" y="90" width="106" height="12" fill="$_brand"/>
  <rect x="226" y="80" width="46" height="7" rx="3.5" fill="#FFFFFF" opacity=".9"/>
  <!-- request card on the screen -->
  <rect x="222" y="112" width="90" height="96" rx="10" fill="#F7F3F4"/>
  <circle cx="238" cy="128" r="9" fill="#F6D6DC"/>
  <rect x="252" y="122" width="40" height="5" rx="2.5" fill="#B9BFC8"/>
  <rect x="252" y="131" width="26" height="4" rx="2" fill="#D6DAE0"/>
  DROP_SCREEN
  <rect x="254" y="150" width="46" height="6" rx="3" fill="#2F3A4A" opacity=".75"/>
  <rect x="254" y="161" width="34" height="5" rx="2.5" fill="#B9BFC8"/>
  <rect x="230" y="186" width="74" height="14" rx="7" fill="$_brand"/>
  <rect x="222" y="216" width="90" height="10" rx="5" fill="#EEF0F3"/>
  <rect x="222" y="232" width="64" height="10" rx="5" fill="#EEF0F3"/>

  <!-- donors answering -->
  <g>
    <circle cx="356" cy="92" r="20" fill="#FFFFFF"/>
    <circle cx="356" cy="86" r="7" fill="$_skin"/>
    <path d="M343 104 C344 94 368 94 369 104Z" fill="$_teal"/>
    <circle cx="370" cy="76" r="8" fill="#2F9E5B"/>
    <path d="M366 76 l3 3 l5 -6" stroke="#FFFFFF" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
  <g>
    <circle cx="364" cy="176" r="18" fill="#FFFFFF"/>
    <circle cx="364" cy="171" r="6.5" fill="$_skin"/>
    <path d="M352 187 C353 178 375 178 376 187Z" fill="#E3A44B"/>
  </g>
  <path d="M332 104 Q344 120 340 136" stroke="#C9DDE5" stroke-width="2" fill="none" stroke-dasharray="3 5" stroke-linecap="round"/>

  <!-- woman -->
  <ellipse cx="128" cy="300" rx="12" ry="5" fill="#2F3A4A"/>
  <ellipse cx="154" cy="300" rx="12" ry="5" fill="#2F3A4A"/>
  <rect x="118" y="200" width="18" height="100" rx="9" fill="$_pants"/>
  <rect x="144" y="200" width="18" height="100" rx="9" fill="$_pants"/>
  <path d="M110 214 Q106 148 140 136 Q174 148 170 214Z" fill="$_teal"/>
  <rect x="133" y="118" width="14" height="22" rx="5" fill="$_skin"/>
  <path d="M118 140 Q114 104 140 82 Q166 104 162 140 L154 140 Q160 104 140 98 Q120 104 126 140Z" fill="$_hair"/>
  <ellipse cx="140" cy="106" rx="19" ry="23" fill="$_skin"/>
  <path d="M120 104 Q118 76 142 78 Q166 80 162 106 Q150 90 128 96 Q124 100 120 104Z" fill="$_hair"/>
  <!-- arm down -->
  <path d="M116 152 L108 200" stroke="$_teal" stroke-width="16" stroke-linecap="round"/>
  <circle cx="107" cy="206" r="7.5" fill="$_skin"/>
  <!-- arm reaching to the phone -->
  <path d="M162 152 L184 160" stroke="$_teal" stroke-width="16" stroke-linecap="round"/>
  <path d="M184 160 L210 140" stroke="$_skin" stroke-width="11" stroke-linecap="round"/>
  <circle cx="212" cy="138" r="7" fill="$_skin"/>

  HEART
</svg>
''';

/// Slide 3: a donor walking along a route to a nearby hospital.
const String nearbyArtSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 340">
  <path d="M50 200 C36 110 120 40 214 44 C312 48 372 116 358 204 C346 282 266 314 186 306 C104 298 60 262 50 200Z" fill="$_blob"/>
  LEAVES_L
  LEAVES_R
  <ellipse cx="200" cy="306" rx="156" ry="8" fill="#DCEBF0"/>

  <!-- hospital -->
  <rect x="226" y="132" width="116" height="170" rx="6" fill="#FFFFFF"/>
  <rect x="226" y="132" width="116" height="14" rx="6" fill="#D9E7ED"/>
  <rect x="270" y="252" width="28" height="50" rx="4" fill="#C9DDE5"/>
  <g fill="#BFE0EC">
    <rect x="240" y="160" width="20" height="18" rx="3"/><rect x="308" y="160" width="20" height="18" rx="3"/>
    <rect x="240" y="192" width="20" height="18" rx="3"/><rect x="308" y="192" width="20" height="18" rx="3"/>
    <rect x="240" y="224" width="20" height="18" rx="3"/><rect x="308" y="224" width="20" height="18" rx="3"/>
  </g>
  <circle cx="284" cy="196" r="16" fill="$_red"/>
  <path d="M284 187 V205 M275 196 H293" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/>

  <!-- map pin over the hospital -->
  <ellipse cx="284" cy="126" rx="14" ry="4" fill="#C9DDE5"/>
  <path d="M284 124 C284 124 254 94 254 70 A30 30 0 0 1 314 70 C314 94 284 124 284 124Z" fill="$_brand"/>
  <circle cx="284" cy="70" r="15" fill="#FFFFFF"/>
  DROP_PIN

  <!-- route -->
  <path d="M120 292 C170 292 190 272 214 262 C232 255 250 262 268 262" stroke="$_brand" stroke-width="3.5" fill="none" stroke-dasharray="2 9" stroke-linecap="round"/>

  <!-- tree -->
  <rect x="62" y="226" width="8" height="74" rx="4" fill="#9C7B62"/>
  <circle cx="66" cy="218" r="26" fill="#B7C77E"/>
  <circle cx="52" cy="234" r="16" fill="$_leaf"/>

  <!-- man walking -->
  <ellipse cx="108" cy="300" rx="12" ry="5" fill="#2F3A4A"/>
  <ellipse cx="150" cy="298" rx="12" ry="5" fill="#2F3A4A"/>
  <path d="M126 206 L110 296" stroke="$_pants" stroke-width="18" stroke-linecap="round"/>
  <path d="M140 206 L148 294" stroke="$_pants" stroke-width="18" stroke-linecap="round"/>
  <path d="M110 216 Q106 150 134 138 Q164 146 162 216Z" fill="#E3A44B"/>
  <rect x="127" y="120" width="14" height="22" rx="5" fill="$_skin"/>
  <ellipse cx="134" cy="108" rx="18" ry="21" fill="$_skin"/>
  <path d="M116 108 Q112 82 136 84 Q156 84 154 100 Q140 96 128 98 Q124 108 116 108Z" fill="$_hair"/>
  <path d="M114 154 L102 194" stroke="#E3A44B" stroke-width="15" stroke-linecap="round"/>
  <circle cx="100" cy="200" r="7" fill="$_skin"/>
  <path d="M158 154 L174 180" stroke="#E3A44B" stroke-width="15" stroke-linecap="round"/>
  <path d="M174 180 L184 164" stroke="$_skin" stroke-width="10" stroke-linecap="round"/>
  <rect x="180" y="146" width="14" height="24" rx="3" fill="#2F3A4A"/>

  <!-- "request near you" bubble -->
  <rect x="18" y="22" width="128" height="44" rx="12" fill="#FFFFFF"/>
  <rect x="18" y="22" width="128" height="44" rx="12" fill="none" stroke="#DCEBF0" stroke-width="1.5"/>
  <path d="M96 65 L108 80 L112 65Z" fill="#FFFFFF"/>
  <rect x="28" y="32" width="24" height="24" rx="7" fill="$_brand"/>
  DROP_BUBBLE
  <rect x="60" y="35" width="70" height="6" rx="3" fill="#2F3A4A" opacity=".75"/>
  <rect x="60" y="47" width="48" height="5" rx="2.5" fill="#B9BFC8"/>
</svg>
''';

String _fill(String svg) => svg
    .replaceFirst('LEAVES_L', _leaves(48, 306))
    .replaceFirst('LEAVES_R', _leaves(352, 306, flip: true))
    .replaceFirst('DROP_SCREEN', _drop(238, 160, 7, _brand))
    .replaceFirst('DROP_PIN', _drop(284, 74, 6.5, _brand))
    .replaceFirst('DROP_BUBBLE', _drop(40, 46, 5.5, '#FFFFFF'))
    .replaceFirst('HEART',
        '<path transform="translate(188 64)" d="M0 6 C-6 -4 -20 0 -16 10 C-13 17 0 24 0 24 C0 24 13 17 16 10 C20 0 6 -4 0 6Z" fill="$_red"/>');

/// The illustration for slide [index] (0, 1 or 2).
class OnboardingArt extends StatelessWidget {
  const OnboardingArt(this.index, {super.key});
  final int index;

  static final _request = _fill(requestArtSvg);
  static final _nearby = _fill(nearbyArtSvg);

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return Image.asset('assets/images/onboard_donate.jpg', fit: BoxFit.contain, excludeFromSemantics: true);
      case 1:
        return SvgPicture.string(_request, fit: BoxFit.contain, excludeFromSemantics: true);
      default:
        return SvgPicture.string(_nearby, fit: BoxFit.contain, excludeFromSemantics: true);
    }
  }
}
