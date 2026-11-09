import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/badges.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'tabs/dashboard_tab.dart';

/// All badges with the user's progress towards each one.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final user = app.user;
    if (user == null) return const SizedBox.shrink();
    final donations = app.donations ?? const <Donation>[];
    final earned = kBadges.where((b) => b.earned(user, donations)).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            PageHeader(app.t('badges')),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.t('earnedOf', {'n': earned, 't': kBadges.length}),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(app.t('badgesSub'), style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: earned / kBadges.length,
                    minHeight: 6,
                    backgroundColor: AppColors.chip,
                    color: AppColors.red,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ListGroup(children: [
              for (final b in kBadges) _BadgeRow(badge: b, user: user, donations: donations),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge, required this.user, required this.donations});
  final BadgeDef badge;
  final AppUser user;
  final List<Donation> donations;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final done = badge.earned(user, donations);
    final p = badge.progress(user, donations).clamp(0, badge.goal);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        BadgeIcon(badge: badge, earned: done, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.t('badge_${badge.key}'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(app.t('badge_${badge.key}_d'), style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          done ? app.t('earned') : '$p/${badge.goal}',
          textDirection: done ? null : TextDirection.ltr,
          style: TextStyle(
            fontSize: 12.5,
            color: done ? AppColors.ink : AppColors.hint,
            fontWeight: done ? FontWeight.w800 : FontWeight.w400,
            fontFamily: done ? null : AppFonts.latin,
          ),
        ),
      ]),
    );
  }
}
