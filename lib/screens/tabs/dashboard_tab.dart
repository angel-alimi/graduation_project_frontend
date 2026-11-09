import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../home_shell.dart';
import '../sheets/new_request_sheet.dart';
import '../sheets/update_donation_sheet.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final user = app.user;
    final shell = ShellScope.of(context);
    final tt = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();

    final last = user.lastDonationDate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Greeting
        Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 100, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.t('hello'), style: const TextStyle(fontSize: 12, color: Color(0xFF6B4750))),
                Text(user.fullName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF6B4750)),
                  const SizedBox(width: 4),
                  Text(app.cityName(user.cityId), style: const TextStyle(fontSize: 12, color: Color(0xFF6B4750))),
                ]),
              ]),
            ),
            const PositionedDirectional(end: 14, bottom: -8, child: Mascot(pose: MascotPose.wave, size: 74)),
          ]),
        ),
        const SizedBox(height: 18),
        Text(app.t('howHelp'), style: tt.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _ActionCard(
              filled: true,
              icon: Icons.bloodtype_outlined,
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
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            _InfoRow(
              icon: Icons.water_drop_outlined,
              label: app.t('yourBloodType'),
              value: Text(user.bloodType.display,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, color: AppColors.red)),
              trailing: const ForwardChevron(),
              onTap: () => shell.go(Tabs.profile),
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: app.t('lastDonation'),
              value: Text(last == null ? app.t('never') : formatDate(last, app.lang),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: Text(app.t('update'), style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 13)),
              onTap: () => showUpdateDonationSheet(context),
            ),
          ]),
        ),
        if (user.daysUntilEligible > 0) ...[
          const SizedBox(height: 10),
          Text(app.t('cooldown', {'n': user.daysUntilEligible}), style: tt.bodySmall),
        ],
      ],
    );
  }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconBox(icon, size: 36, bg: filled ? const Color(0x29FFFFFF) : AppColors.soft, fg: filled ? Colors.white : AppColors.red),
            const SizedBox(height: 18),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: filled ? const Color(0xFFFBE3E7) : AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.trailing, required this.onTap});
  final IconData icon;
  final String label;
  final Widget value;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Row(children: [
            IconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                value,
              ]),
            ),
            trailing,
          ]),
        ),
      );
}
