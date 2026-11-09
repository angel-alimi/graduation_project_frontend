import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme.dart';
import '../../models/badges.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../badges_screen.dart';
import '../donation_history_screen.dart';
import '../home_shell.dart';
import '../sheets/new_request_sheet.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    final app = context.appRead;
    if (app.donations == null) app.loadDonations().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final user = app.user;
    final shell = ShellScope.of(context);
    if (user == null) return const SizedBox.shrink();

    final donations = app.donations ?? const <Donation>[];
    final earned = kBadges.where((b) => b.earned(user, donations)).length;

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        await Future.wait([app.loadDonations(), app.refreshUser()]).catchError((_) => <void>[]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Greeting
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.t('hello'), style: TextStyle(fontSize: 12, color: AppColors.hint)),
                  Text(user.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(app.cityName(user.cityId), style: TextStyle(fontSize: 12, color: AppColors.hint)),
                ]),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(16)),
                child: Center(child: BloodLabel(user.bloodType, size: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Main actions
          Row(children: [
            Expanded(
              child: _ActionCard(
                filled: true,
                icon: Icons.add_rounded,
                title: app.t('requestBlood'),
                subtitle: app.t('requestBloodSub'),
                onTap: () async {
                  final created = await showNewRequestSheet(context);
                  if (created == true) shell.go(Tabs.requests, segment: 0);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.favorite_border_rounded,
                title: app.t('donateBlood'),
                subtitle: app.t('donateBloodSub'),
                onTap: () => shell.go(Tabs.requests, segment: 1),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Eligibility
          _EligibilityCard(user: user),
          const SizedBox(height: 12),

          // Stats
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: IntrinsicHeight(
              child: Row(children: [
                _Stat(value: '${donations.length}', label: app.t('statDonations')),
                const VerticalDivider(width: 1),
                _Stat(value: '${livesHelped(donations)}', label: app.t('statLives')),
                const VerticalDivider(width: 1),
                _Stat(value: '$earned', label: app.t('statBadges')),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Donations
          SectionLabel(app.t('donationsSection')),
          ListGroup(children: [
            ListRow(
              icon: Icons.history_rounded,
              label: app.t('donationRecord'),
              value: '${donations.length}',
              valueLatin: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonationHistoryScreen())),
            ),
          ]),
          const SizedBox(height: 16),

          // Rewards
          SectionLabel(app.t('rewards')),
          AppCard(
            padding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgesScreen())),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  for (final b in kBadges) BadgeIcon(badge: b, earned: b.earned(user, donations)),
                ]),
              ),
              const Divider(height: 1),
              ListRow(
                icon: Icons.emoji_events_outlined,
                label: app.t('earnedOf', {'n': earned, 't': kBadges.length}),
                value: app.t('viewAll'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgesScreen())),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// "You can donate now" / "Next donation in N days" with a progress bar.
class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final left = user.daysUntilEligible;
    final last = user.lastDonationDate;
    const total = AppConfig.donationCooldownDays;
    final progress = left == 0 ? 1.0 : (total - left) / total;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.event_available_outlined, size: 20, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(left == 0 ? app.t('readyToDonate') : app.t('nextIn', {'n': left}),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: AppColors.chip, color: AppColors.red),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          last == null
              ? app.t('firstDonationSub')
              : left == 0
                  ? app.t('readySub')
                  : app.t('lastOn', {'d': formatDate(last, app.lang)}),
          style: TextStyle(fontSize: 12.5, color: AppColors.hint),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.hint)),
        ]),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap, this.filled = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.ink;
    return Material(
      color: filled ? AppColors.red : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 22, color: filled ? Colors.white : AppColors.muted),
            const SizedBox(height: 22),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: filled ? const Color(0xE6FFFFFF) : AppColors.hint)),
          ]),
        ),
      ),
    );
  }
}

/// Round badge icon: dark when earned, faded when not yet.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.badge, required this.earned, this.size = 46});
  final BadgeDef badge;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: context.tr('badge_${badge.key}'),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? AppColors.chip : AppColors.surface,
            border: Border.all(color: earned ? AppColors.chip : AppColors.field, width: 1.2),
          ),
          child: Icon(badge.icon, size: size * .48, color: earned ? AppColors.ink : AppColors.field),
        ),
      );
}
