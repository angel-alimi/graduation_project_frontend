import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../core/share_request.dart';
import 'common.dart';

/// One button in the action bar at the bottom of a [RequestCard].
class PostAction {
  const PostAction({
    this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
    this.destructive = false,
    this.done = false,
    this.count,
    this.subtle = false,
  });
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

  /// Bold dark text, for the main thing to do on the post (e.g. Accept).
  final bool primary;
  final bool destructive;

  /// A grey, non-tappable status (e.g. "Response sent").
  final bool done;

  /// Small number shown in a badge after the label (e.g. responders).
  final int? count;

  /// Plain text link with no border (e.g. Details), placed at the bottom corner.
  final bool subtle;
}

/// Post for a blood request (feed, matched list, "my requests").
///
/// Layout: avatar + name + city/time with Share and ⋯ on the other side;
/// the note when there is one; a bordered panel with the blood type and units
/// on one side and the patient, hospital and "needed before" on the other;
/// then the main action (red) and an outlined secondary action.
class RequestCard extends StatelessWidget {
  const RequestCard(
      {super.key,
      required this.request,
      this.actions = const [],
      this.menu = const [],
      this.onTap});
  final BloodRequest request;
  final List<PostAction> actions;

  /// Extra options behind the ⋯ button in the header (e.g. Cancel request).
  final List<PostAction> menu;
  final VoidCallback? onTap;

  /// "Today, 6:00 PM", "Tomorrow, 9:00 AM" or "12 Nov · 9:00 AM".
  static String _when(AppState app, DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final time = formatTime(d.hour, d.minute, app.lang);
    final diff = day.difference(today).inDays;
    final sep = app.lang == 'ar' ? '، ' : ', ';
    if (diff == 0) return '${app.t('today')}$sep$time';
    if (diff == 1) return '${app.t('tomorrow')}$sep$time';
    // The year only when it is not this year, so the line fits the panel.
    if (d.year == now.year) {
      return '${d.day} ${monthName(d.month, app.lang)} · $time';
    }
    return formatDateTime(d, app.lang);
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first.characters.first;
    // Arabic letters join into a word, so Arabic names get a single letter.
    if (userTextDirection(name) == TextDirection.rtl) return a;
    final b = parts.length > 1 ? parts[1].characters.first : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final r = request;
    final poster =
        r.mine ? (app.user?.fullName ?? r.requesterName) : r.requesterName;
    final patient = r.patientName;
    final primary = actions.where((a) => a.primary || a.done).toList();
    final secondary = actions.where((a) => !(a.primary || a.done)).toList();

    final line = AppColors.line;
    final note = (r.note ?? '').trim();

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header: avatar, name, city · time; share and ⋯. Laid out in the
            // direction of the app like every other post; only the name
            // itself reads in its own direction.
            Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.chip, shape: BoxShape.circle),
                child: Text(_initials(poster),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: AppColors.muted)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(poster,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: userTextDirection(poster),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: AppColors.ink)),
                      Text(
                          '${app.cityName(r.cityId)} · ${app.timeAgo(r.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.hint)),
                    ]),
              ),
              // The icons have their own inner space, so they are pulled out
              // to line up with the edge of the panel below.
              Transform.translate(
                offset: Offset(
                    Directionality.of(context) == TextDirection.rtl ? -8 : 8,
                    0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _HeaderIcon(
                    icon: Icons.share_outlined,
                    tooltip: app.t('share'),
                    onTap: () => shareRequest(context, r),
                  ),
                  if (menu.isNotEmpty) _Menu(menu),
                ]),
              ),
            ]),

            // Note: under the header, like the text of a post, only when the
            // requester wrote one.
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(2, 10, 2, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: userTextDirection(note),
                      style: TextStyle(
                          fontSize: 13.5, height: 1.5, color: AppColors.ink)),
                ),
              ),
            const SizedBox(height: 12),

            // Bordered panel: blood type | patient, hospital, needed before.
            Container(
              height: _panel,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lightly tinted square for the blood type.
                    Container(
                      width: _panel - 2, // square inside the 1px border
                      color: AppColors.soft.withValues(alpha: .6),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(r.bloodType.display,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: AppColors.ink)),
                            const SizedBox(height: 3),
                            Text(
                                app.t(
                                    r.unitsNeeded == 1
                                        ? 'unitOne'
                                        : 'unitMany',
                                    {'n': r.unitsNeeded}),
                                style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.3,
                                    color: AppColors.muted)),
                          ]),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: line),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((patient ?? '').isNotEmpty) ...[
                                Text(app.t('patient'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        height: 1.3,
                                        color: AppColors.hint)),
                                Text(patient!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: userTextDirection(patient),
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                        color: AppColors.ink)),
                              ],
                              Text(app.hospitalName(r.hospitalId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.45,
                                      color: AppColors.ink)),
                              if (r.neededAt != null)
                                Text(
                                    app.t('neededBy',
                                        {'d': _when(app, r.neededAt!)}),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: AppColors.redText)),
                            ]),
                      ),
                    ),
                  ]),
            ),

            // Actions. A card with only a quiet link (e.g. Details) shows it
            // as plain text at the bottom corner; the link is short, so the
            // space under it matches the space above the header.
            if (actions.isNotEmpty && actions.every((a) => a.subtle))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _TextAction(actions.first),
                ),
              )
            else if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(children: [
                  for (final a in primary) ...[
                    Expanded(child: _PrimaryPill(a)),
                    if (a != primary.last) const SizedBox(width: 8),
                  ],
                  for (final a in secondary) ...[
                    if (primary.isNotEmpty || a != secondary.first)
                      const SizedBox(width: 8),
                    primary.isEmpty
                        ? Expanded(child: _OutlinePill(a))
                        : _OutlinePill(a),
                  ],
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon, size: 19, color: AppColors.muted),
        ),
      );
}

/// ⋯ menu in the card header.
class _Menu extends StatelessWidget {
  const _Menu(this.items);
  final List<PostAction> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: PopupMenuButton<int>(
          tooltip: '',
          padding: EdgeInsets.zero,
          icon:
              Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.muted),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: AppColors.surface,
          onSelected: (i) => items[i].onTap?.call(),
          itemBuilder: (_) => [
            for (var i = 0; i < items.length; i++)
              PopupMenuItem<int>(
                value: i,
                child: Row(children: [
                  Icon(items[i].icon ?? Icons.more_horiz_rounded,
                      size: 20,
                      color:
                          items[i].destructive ? AppColors.redText : AppColors.ink),
                  const SizedBox(width: 12),
                  Text(items[i].label,
                      style: TextStyle(
                          fontSize: 14,
                          color: items[i].destructive
                              ? AppColors.redText
                              : AppColors.ink)),
                ]),
              ),
          ],
        ),
      );
}

const _pillHeight = 38.0;

/// Height of the blood-type / details panel (the blood-type box is a square of this size).
const _panel = 88.0;

/// Main action: solid red pill, or a grey status pill when done.
class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill(this.a);
  final PostAction a;

  @override
  Widget build(BuildContext context) {
    final fg = a.done ? AppColors.muted : Colors.white;
    return Material(
      color: a.done ? AppColors.chip : AppColors.red,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: a.done ? null : a.onTap,
        child: SizedBox(
          height: _pillHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(a.count == null ? a.label : '${a.label} (${a.count})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet link: text and a small chevron, no border or fill (e.g. Details).
class _TextAction extends StatelessWidget {
  const _TextAction(this.a);
  final PostAction a;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: a.onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 24),
          padding: const EdgeInsetsDirectional.only(start: 10, end: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(a.label),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ]),
      );
}

/// Secondary action: outlined pill with a text label (e.g. Contact).
class _OutlinePill extends StatelessWidget {
  const _OutlinePill(this.a);
  final PostAction a;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: AppColors.field)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: a.onTap,
          child: SizedBox(
            height: _pillHeight,
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(a.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
              ),
            ),
          ),
        ),
      );
}

/// Secondary pill button used inside cards ("Details", "Cancel request").
/// [destructive] tints it red; [done] turns it into a non-tappable grey status label.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    this.onPressed,
    this.done = false,
    this.destructive = false,
    this.icon,
    this.trailingIcon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool done;
  final bool destructive;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration:
            ShapeDecoration(color: AppColors.chip, shape: StadiumBorder()),
        child:
            Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted)),
      );
    }
    final fg = destructive ? AppColors.redText : AppColors.ink;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(0, 38),
        padding: EdgeInsetsDirectional.only(
            start: icon != null ? 14 : 18, end: trailingIcon != null ? 12 : 18),
        shape: const StadiumBorder(),
        side: BorderSide(
            color: destructive
                ? AppColors.redText.withValues(alpha: .35)
                : AppColors.field,
            width: 1.2),
        textStyle: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Text(label),
        // Arrow / chevron icons mirror themselves in right-to-left (Arabic).
        if (trailingIcon != null) ...[
          const SizedBox(width: 4),
          Icon(trailingIcon, size: 18),
        ],
      ]),
    );
  }
}

/// Solid, fully rounded (pill) call-to-action button used inside cards, e.g. "Accept".
class AcceptButton extends StatelessWidget {
  const AcceptButton(
      {super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(96, 38),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Text(label),
      ]),
    );
  }
}

/// Small share icon shown at the top of a post. Opens the phone's share menu.
class ShareIconButton extends StatelessWidget {
  const ShareIconButton({super.key, required this.request});
  final BloodRequest request;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: context.tr('share'),
          icon: Icon(Icons.share_outlined, size: 19, color: AppColors.muted),
          onPressed: () => shareRequest(context, request),
        ),
      );
}
