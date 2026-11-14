import 'package:flutter/material.dart';

import '../core/theme.dart';

/// One slot of the bottom bar: a tab, or (with [BottomBarItem.action]) a
/// button that runs an action instead of switching tabs.
class BottomBarItem {
  const BottomBarItem(this.icon, this.label, {this.badge = false})
      : onAction = null,
        primary = false;

  /// An action slot. [primary] draws it as the raised red "+" circle;
  /// otherwise it looks like a tab icon. [badge] adds a small red dot.
  const BottomBarItem.action(this.icon, this.label, VoidCallback this.onAction, {this.primary = false, this.badge = false});

  final IconData icon;
  final String label;
  final VoidCallback? onAction;
  final bool primary;
  final bool badge;

  bool get isAction => onAction != null;
}

/// The LifeShare bottom bar: a soft rounded bar where a red circle slides
/// under the active tab and lifts its icon up. A primary action (the "+")
/// is always shown raised in its own red circle. The slots keep the same
/// left-to-right order in Arabic and English, so switching language never
/// moves an icon.
class LifeShareBottomBar extends StatelessWidget {
  const LifeShareBottomBar({super.key, required this.items, required this.index, required this.onTap});
  final List<BottomBarItem> items;

  /// Index (in [items]) of the active tab.
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
    final textDir = Directionality.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
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
              // Sliding indicator under the active tab
              AnimatedPositioned(
                key: const ValueKey('bar-indicator'),
                duration: _duration,
                curve: _curve,
                top: _circleTop,
                left: index * w + (w - _circle) / 2,
                child: Container(
                  width: _circle,
                  height: _circle,
                  decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                ),
              ),
              Positioned.fill(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < items.length; i++) Expanded(child: _item(context, i, textDir)),
                ]),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text, bool on, TextDirection textDir) => Positioned(
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
          child: Text(text, textAlign: TextAlign.center, textDirection: textDir, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );

  Widget _item(BuildContext context, int i, TextDirection textDir) {
    final item = items[i];

    // Raised red "+"
    if (item.primary) {
      return Semantics(
        button: true,
        label: item.label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: item.onAction,
          radius: 32,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              top: _circleTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: _circle,
                  height: _circle,
                  decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
                ),
              ),
            ),
            _label(context, item.label, true, textDir),
          ]),
        ),
      );
    }

    final on = !item.isAction && i == index;
    return Semantics(
      selected: on,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: item.isAction ? item.onAction : () => onTap(i),
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
              child: Stack(clipBehavior: Clip.none, children: [
                TweenAnimationBuilder<Color?>(
                  duration: const Duration(milliseconds: 300),
                  tween: ColorTween(end: on ? Colors.white : AppColors.muted2),
                  builder: (_, color, __) => Icon(item.icon, size: _icon, color: color),
                ),
                if (item.badge)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navBg, width: 1.5),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          _label(context, item.label, on, textDir),
        ]),
      ),
    );
  }
}
