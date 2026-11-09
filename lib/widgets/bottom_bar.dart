import 'package:flutter/material.dart';

import '../core/theme.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  const BottomBarItem(this.icon, this.label);
}

/// The LifeShare bottom bar: a soft rounded bar where a red circle slides
/// under the active icon and lifts it up. Works in RTL and LTR.
class LifeShareBottomBar extends StatelessWidget {
  const LifeShareBottomBar({super.key, required this.items, required this.index, required this.onTap});
  final List<BottomBarItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const _barHeight = 56.0;
  static const _circle = 38.0;
  static const _circleTop = -15.0;
  static const _icon = 21.0;

  // The icon is placed by coordinates, so font metrics of the label can't shift it.
  static const _iconTopActive = _circleTop + (_circle - _icon) / 2;
  static const _iconTopIdle = 10.0;
  static const _curve = Cubic(.34, 1.22, .64, 1);
  static const _duration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom > 0 ? bottom : 12),
      child: SizedBox(
        height: _barHeight,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth / items.length;
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.navBg, borderRadius: BorderRadius.circular(16)),
              ),
            ),
            AnimatedPositionedDirectional(
              duration: _duration,
              curve: _curve,
              top: _circleTop,
              start: index * w + (w - _circle) / 2,
              child: Container(
                width: _circle,
                height: _circle,
                decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
              ),
            ),
            Positioned.fill(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(child: _item(context, i)),
              ]),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    final on = i == index;
    final item = items[i];
    return Semantics(
      selected: on,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: () => onTap(i),
        radius: 32,
        child: Stack(clipBehavior: Clip.none, children: [
          AnimatedPositioned(
            duration: _duration,
            curve: _curve,
            top: on ? _iconTopActive : _iconTopIdle,
            left: 0,
            right: 0,
            height: _icon,
            child: Center(
              child: TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 300),
                tween: ColorTween(end: on ? Colors.white : AppColors.muted2),
                builder: (_, color, __) => Icon(item.icon, size: _icon, color: color),
              ),
            ),
          ),
          Positioned(
            left: 2,
            right: 2,
            bottom: 7,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: on ? FontWeight.w800 : FontWeight.w400,
                color: on ? AppColors.ink : AppColors.muted2,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
              child: Text(item.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      ),
    );
  }
}
