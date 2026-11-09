import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/badges.dart';
import '../state/app_state.dart';
import 'common.dart';

/// Plain trophy button for the donor's level, placed on the side opposite the name.
/// Outlined and faded before the first donation, solid once a level is reached.
/// Tapping it opens the level sheet.
class LevelTrophy extends StatelessWidget {
  const LevelTrophy({super.key, required this.donations});
  final int donations;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final level = levelFor(donations);
    final reached = level.minDonations > 0;
    return Tooltip(
      message: app.t('badge_${level.key}'),
      child: Material(
        color: AppColors.chip,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showLevelSheet(context, donations),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              reached ? Icons.emoji_events_rounded : Icons.emoji_events_outlined,
              size: 18,
              color: reached ? AppColors.ink : AppColors.hint,
            ),
          ),
        ),
      ),
    );
  }
}

/// Current level, progress to the next one, and every level with what it takes.
Future<void> showLevelSheet(BuildContext context, int donations) {
  final app = context.appRead;
  return showAppSheet<void>(context, title: app.t('levelTitle'), builder: (_) => _LevelBody(donations));
}

class _LevelBody extends StatelessWidget {
  const _LevelBody(this.donations);
  final int donations;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final current = levelFor(donations);
    final next = nextLevel(donations);

    final String hint;
    if (next == null) {
      hint = app.t('levelMax');
    } else {
      final left = next.minDonations - donations;
      hint = app.t(left == 1 ? 'levelNext1' : 'levelNext', {'n': left, 'name': app.t('badge_${next.key}')});
    }
    final from = current.minDonations;
    final progress = next == null ? 1.0 : (donations - from) / (next.minDonations - from);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.emoji_events_outlined, size: 20, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(app.t('badge_${current.key}'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            Text('$donations',
                style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.chip,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text(hint, style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
        ]),
      ),
      const SizedBox(height: 12),
      SectionLabel(app.t('levelSub')),
      ListGroup(children: [
        for (final l in kLevels.skip(1)) _LevelRow(level: l, reached: donations >= l.minDonations),
      ]),
    ]);
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.reached});
  final DonorLevel level;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? AppColors.chip : AppColors.surface,
            border: Border.all(color: reached ? AppColors.chip : AppColors.field, width: 1.2),
          ),
          child: Icon(Icons.emoji_events_outlined, size: 18, color: reached ? AppColors.ink : AppColors.field),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.t('badge_${level.key}'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(app.t('badge_${level.key}_d'), style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
          ]),
        ),
        if (reached) Icon(Icons.check_rounded, size: 18, color: AppColors.ink),
      ]),
    );
  }
}
