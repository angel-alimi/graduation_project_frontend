import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../core/share_request.dart';
import 'common.dart';

/// Card for a blood request in the feed, the matched list or "my requests".
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, this.action, this.onTap});
  final BloodRequest request;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final r = request;
    final title = r.mine ? (r.patientName ?? app.user?.fullName ?? r.requesterName) : r.requesterName;
    return AppCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, textDirection: userTextDirection(title), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${app.cityName(r.cityId)} · ${app.timeAgo(r.createdAt)}',
                  style: TextStyle(fontSize: 12, color: AppColors.hint)),
            ]),
          ),
          ShareIconButton(request: r),
        ]),
        const SizedBox(height: 10),
        Text(app.t('needs', {'units': r.unitsNeeded, 'bt': r.bloodType.display}),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
        if ((r.note ?? '').isNotEmpty) ...[
          const SizedBox(height: 2),
          UserText(r.note!, style: const TextStyle(fontSize: 13.5, height: 1.6)),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(app.hospitalName(r.hospitalId), style: Theme.of(context).textTheme.bodySmall)),
        ]),
        if (r.neededAt != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(child: Text(formatDateTime(r.neededAt!, app.lang), style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ],
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 10),
        Row(children: [
          BloodLabel(r.bloodType),
          const SizedBox(width: 8),
          // Shrinks the buttons slightly on very narrow screens instead of overflowing.
          if (action != null)
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: action!),
              ),
            ),
        ]),
      ]),
    );
  }
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
        decoration: ShapeDecoration(color: AppColors.chip, shape: StadiumBorder()),
        child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted)),
      );
    }
    final fg = destructive ? AppColors.red : AppColors.ink;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(0, 38),
        padding: EdgeInsetsDirectional.only(start: icon != null ? 14 : 18, end: trailingIcon != null ? 12 : 18),
        shape: const StadiumBorder(),
        side: BorderSide(color: destructive ? AppColors.red.withValues(alpha: .35) : AppColors.field, width: 1.2),
        textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Text(label),
        // Trailing icon is a forward chevron: mirror it in right-to-left (Arabic).
        if (trailingIcon != null) ...[
          const SizedBox(width: 4),
          Transform.flip(
            flipX: Directionality.of(context) == TextDirection.rtl,
            child: Icon(trailingIcon, size: 18),
          ),
        ],
      ]),
    );
  }
}

/// Solid, fully rounded (pill) call-to-action button used inside cards, e.g. "Accept".
class AcceptButton extends StatelessWidget {
  const AcceptButton({super.key, required this.label, this.onPressed, this.icon});
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
        textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
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
