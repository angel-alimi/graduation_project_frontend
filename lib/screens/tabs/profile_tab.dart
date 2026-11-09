import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../home_shell.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Refresh counts (requests / responses) from the backend.
    context.appRead.refreshUser().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final u = app.user;
    if (u == null) return const SizedBox.shrink();
    final shell = ShellScope.of(context);
    final initial = u.fullName.trim().isEmpty ? '?' : u.fullName.trim().characters.first;

    Widget row(IconData icon, String label, Widget value) => SizedBox(
          height: 54,
          child: Row(children: [
            IconBox(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
            value,
          ]),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(children: [
          Expanded(child: Text(app.t('profile'), style: Theme.of(context).textTheme.titleLarge)),
          TextButton.icon(
            onPressed: () => context.toast(app.t('editSoon')),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(app.t('edit')),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink, backgroundColor: AppColors.chip),
          ),
        ]),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
              child: Text(initial, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 21)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(app.cityName(u.cityId), style: Theme.of(context).textTheme.bodySmall),
                ]),
              ]),
            ),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(8)),
              child: Text(u.bloodType.display,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Count(label: app.t('myRequests'), value: u.requestsCount)),
          const SizedBox(width: 12),
          Expanded(child: _Count(label: app.t('myResponses'), value: u.responsesCount)),
        ]),
        const SizedBox(height: 14),
        SectionLabel(app.t('personalInfo')),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            row(Icons.phone_outlined, app.t('phone'),
                Text(formatPhone(u.phone), textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 13))),
            const Divider(),
            row(Icons.person_outline_rounded, app.t('gender'),
                Text(app.t(u.gender == Gender.female ? 'female' : 'male'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
            const Divider(),
            row(Icons.cake_outlined, app.t('birthDate'),
                Text(formatYmd(u.birthDate), textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 13))),
            const Divider(),
            row(Icons.water_drop_outlined, app.t('lastDonation'),
                Text(u.lastDonationDate == null ? app.t('never') : formatDate(u.lastDonationDate!, app.lang),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () => shell.go(Tabs.settings),
          child: SizedBox(
            height: 54,
            child: Row(children: [
              const IconBox(Icons.tune_rounded, bg: AppColors.chip, fg: AppColors.ink),
              const SizedBox(width: 12),
              Expanded(child: Text(app.t('accountSettings'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              const ForwardChevron(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text('$value', style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 19)),
        ]),
      );
}
