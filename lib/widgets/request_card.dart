import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
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
    final initial = r.requesterName.trim().isEmpty ? '?' : r.requesterName.trim().characters.first;
    return AppCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
            child: Text(initial, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, textDirection: userTextDirection(title), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              Text('${app.cityName(r.cityId)} · ${app.timeAgo(r.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          UrgencyTag(r.urgency),
        ]),
        const SizedBox(height: 10),
        Text(app.t('needs', {'units': r.unitsNeeded, 'bt': r.bloodType.display}),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
        if ((r.note ?? '').isNotEmpty) ...[
          const SizedBox(height: 2),
          UserText(r.note!, style: const TextStyle(fontSize: 13.5, height: 1.6)),
        ],
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(app.hospitalName(r.hospitalId), style: Theme.of(context).textTheme.bodySmall)),
        ]),
        if (r.neededAt != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(child: Text(formatDateTime(r.neededAt!, app.lang), style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ],
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 10),
        Row(children: [
          BloodLabel(r.bloodType),
          const Spacer(),
          if (action != null) action!,
        ]),
      ]),
    );
  }
}

/// Small pink button used inside cards.
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, this.onPressed, this.done = false});
  final String label;
  final VoidCallback? onPressed;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: done ? AppColors.greenBg : AppColors.soft,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: done ? null : onPressed,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: done ? AppColors.green : AppColors.red)),
        ),
      ),
    );
  }
}
