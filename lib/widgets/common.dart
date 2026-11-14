import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Small drop logo + "LifeShare" wordmark.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, this.height = 26, this.fontSize = 16, this.spaced = false});
  final double height;
  final double fontSize;
  final bool spaced;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/images/logo_drop.png', height: height),
      SizedBox(width: 7),
      Wordmark(fontSize: fontSize, spaced: spaced),
    ]);
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 16, this.spaced = false});
  final double fontSize;
  final bool spaced;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontFamily: AppFonts.brand, fontWeight: FontWeight.w800, fontSize: fontSize, height: 1.1);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(TextSpan(children: [
        TextSpan(text: spaced ? 'Life ' : 'Life', style: style.copyWith(color: AppColors.ink)),
        TextSpan(text: 'Share', style: style.copyWith(color: AppColors.redText)),
      ])),
    );
  }
}

/// Rounded white card on the grey page background (no border).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.onTap, this.outlined = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  /// Adds a thin hairline border around the card.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Material(
      color: color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: outlined ? BorderSide(color: AppColors.line) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Icon in a fixed-size slot. Plain grey outline by default; pass [bg] for a tinted square.
class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.size = 32, this.bg = Colors.transparent, this.fg});
  final IconData icon;
  final double size;
  final Color bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .28)),
        alignment: Alignment.center,
        child: Icon(icon, size: size * (bg == Colors.transparent ? .66 : .5), color: fg ?? AppColors.muted),
      );
}

/// Chevron that points "forward" in both RTL and LTR. The Material chevron
/// mirrors itself in right-to-left, so it must not be swapped by hand.
class ForwardChevron extends StatelessWidget {
  const ForwardChevron({super.key, this.color, this.size = 20});
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => Icon(
        Icons.chevron_right_rounded,
        color: color ?? AppColors.hint,
        size: size,
      );
}

/// Square back button (the arrow flips automatically in RTL).
class BackSquareButton extends StatelessWidget {
  const BackSquareButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SquareIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: context.tr('back'),
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      );
}

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 40, this.filled = false, this.badge = false});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool filled;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: filled ? AppColors.chip : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size * .3),
        side: filled ? BorderSide.none : BorderSide(color: AppColors.field),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * .3)),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(alignment: Alignment.center, children: [
            Icon(icon, size: size * .48, color: onPressed == null ? AppColors.hint : AppColors.ink),
            if (badge)
              PositionedDirectional(
                top: size * .22,
                end: size * .24,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: AppColors.chip, width: 1.5)),
                ),
              ),
          ]),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Primary red button with a built-in loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon, this.height = 48, this.radius = 12});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ]),
    );
  }
}

/// "ع | EN" segmented switch.
class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    Widget seg(String code, String label, String font) {
      final on = app.lang == code;
      return GestureDetector(
        onTap: () => app.setLang(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 38),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: on ? [BoxShadow(color: AppColors.shadow, blurRadius: 3, offset: Offset(0, 1))] : null,
          ),
          child: Text(label,
              style: TextStyle(fontFamily: font, fontSize: 12, fontWeight: FontWeight.w800, color: on ? AppColors.ink : AppColors.muted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('ar', 'ع', AppFonts.arabic),
        seg('en', 'EN', AppFonts.latin),
      ]),
    );
  }
}

/// Pill button that switches to the other language (used on the welcome screen).
class LangPill extends StatelessWidget {
  const LangPill({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Material(
      color: AppColors.chip,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: app.toggleLang,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.translate_rounded, size: 18, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(app.t('otherLang'),
                style: TextStyle(fontSize: 13, fontFamily: app.lang == 'ar' ? AppFonts.latin : AppFonts.arabic, color: AppColors.ink)),
          ]),
        ),
      ),
    );
  }
}

/// Back button + "Step n of 3" + progress bar.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step, this.showSteps = true, this.onBack});
  final int step;
  final bool showSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      BackSquareButton(onPressed: onBack),
      const SizedBox(width: 12),
      Expanded(
        child: Visibility(
          visible: showSteps,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('step', {'n': step}), style: Theme.of(context).textTheme.bodySmall),
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
                        backgroundColor: AppColors.field,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 5),
              ],
            ]),
          ]),
        ),
      ),
    ]);
  }
}

/// Title + subtitle block used at the top of form screens.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: tt.titleLarge),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: tt.bodyMedium!.copyWith(color: AppColors.muted)),
      ],
    ]);
  }
}

/// Wraps Latin text (e.g. "B+") so it keeps its own order inside an Arabic sentence
/// instead of showing as "+B".
String bidiIsolate(String s) => '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';

/// The direction text written by a user should read in, whatever the app language is.
TextDirection userTextDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

/// Text written by a user. It is shown exactly as written, never translated, and
/// reads in its own direction (an Arabic note stays RTL when the app is in English).
class UserText extends StatelessWidget {
  const UserText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Text(
          text,
          style: style,
          textAlign: TextAlign.start,
          textDirection: userTextDirection(text),
        ),
      );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});
  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          if (optional)
            TextSpan(text: '  ${context.tr('optional')}', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, top: 6, bottom: 4),
        child: Text(text, style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
      );
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {super.key});
  final String? text;
  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(text!, style: TextStyle(fontSize: 12, color: AppColors.error)),
              ),
      );
}

/// Selectable chip (blood types, gender).
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({super.key, required this.label, required this.selected, required this.onTap, this.latinFont = false, this.height = 40});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool latinFont;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.red : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.red : AppColors.field),
          ),
          child: Text(
            label,
            textDirection: latinFont ? TextDirection.ltr : null,
            style: TextStyle(
              fontFamily: latinFont ? AppFonts.latin : null,
              fontWeight: FontWeight.w800,
              fontSize: latinFont ? 14 : 13,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// 4×2 grid of blood types.
class BloodTypeGrid extends StatelessWidget {
  const BloodTypeGrid({super.key, required this.value, required this.onChanged});
  final BloodType? value;
  final ValueChanged<BloodType> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2,
      children: [
        for (final b in BloodType.values)
          ChoiceTile(label: b.display, selected: value == b, latinFont: true, onTap: () => onChanged(b)),
      ],
    );
  }
}

/// Small red drop + blood type in dark text, e.g. "● B+".
class BloodLabel extends StatelessWidget {
  const BloodLabel(this.type, {super.key, this.size = 14});
  final BloodType type;
  final double size;
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.water_drop_rounded, size: size, color: AppColors.redText),
          const SizedBox(width: 3),
          Text(type.display, style: TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: size, color: AppColors.ink)),
        ]),
      );
}

/// Blood type on its own (no drop): bold dark text in a light grey rounded box.
class BloodTypeTag extends StatelessWidget {
  const BloodTypeTag(this.type, {super.key, this.small = false});
  final BloodType type;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minWidth: small ? 34 : 44),
        height: small ? 24 : 32,
        padding: EdgeInsets.symmetric(horizontal: small ? 7 : 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(small ? 7 : 10),
        ),
        child: Text(type.display,
            textDirection: TextDirection.ltr,
            style: TextStyle(
                fontFamily: AppFonts.latin, fontSize: small ? 12.5 : 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
      );
}

/// Centred empty state: an outline icon in a soft circle, a title and a line of help.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.subtitle, this.icon = Icons.inbox_outlined});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 36, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

/// Error state with a retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 32),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: Text(context.tr('retry'))),
          ]),
        ),
      );
}

/// Centered confirmation pop-up, like the alerts of big apps: title and message
/// centered, the main action as a full-width button, Cancel as plain text under it.
/// Returns true when the main action is tapped.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35, color: AppColors.ink)),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.muted)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            child: Text(confirmLabel),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              minimumSize: const Size.fromHeight(46),
              shape: const StadiumBorder(),
            ),
            child: Text(cancelLabel ?? ctx.tr('cancel'), style: const TextStyle(fontSize: 15)),
          ),
        ]),
      ),
    ),
  );
}

/// Opens a bottom sheet styled like the prototype.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.bg,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(ctx).textTheme.titleLarge!.copyWith(fontSize: 18))),
              SquareIconButton(icon: Icons.close_rounded, size: 36, tooltip: ctx.tr('close'), onPressed: () => Navigator.of(ctx).pop()),
            ]),
            const SizedBox(height: 14),
            builder(ctx),
          ]),
        ),
      ),
    ),
  );
}

/// White rounded group of rows separated by hairlines (settings-list style).
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 50),
            children[i],
          ],
        ]),
      );
}

/// One row inside a [ListGroup]: grey outline icon, label, optional grey value, chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueLatin = false,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final String? value;
  final bool valueLatin;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final chevron = showChevron ?? (onTap != null && trailing == null);
    final fg = destructive ? AppColors.redText : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
          child: Row(children: [
            Icon(icon, size: 20, color: destructive ? AppColors.redText : AppColors.muted),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: fg))),
            if (value != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Text(value!,
                    textDirection: valueLatin ? TextDirection.ltr : null,
                    style: TextStyle(fontSize: 13, color: AppColors.hint, fontFamily: valueLatin ? AppFonts.latin : null)),
              ),
            if (trailing != null) trailing!,
            if (chevron) const ForwardChevron(size: 20),
          ]),
        ),
      ),
    );
  }
}

/// Page header used by pushed screens: back button and a centred title.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Stack(alignment: Alignment.center, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Align(alignment: AlignmentDirectional.centerStart, child: BackSquareButton()),
          if (action != null) Align(alignment: AlignmentDirectional.centerEnd, child: action!),
        ]),
      );
}
