import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../../widgets/level_badge.dart';
import '../donation_history_screen.dart';
import '../home_shell.dart';
import '../terms_screen.dart';
import '../welcome_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

/// Profile and settings on one screen.
class _ProfileTabState extends State<ProfileTab> {
  Future<void> _confirmLogout(BuildContext context) async {
    final app = context.appRead;
    final yes = await showConfirmDialog(
      context,
      title: app.t('logoutQ'),
      message: app.t('logoutSub'),
      confirmLabel: app.t('logout'),
    );
    if (yes != true || !context.mounted) return;
    await app.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  void _chooseLanguage(BuildContext context) {
    final app = context.appRead;
    showAppSheet<void>(
      context,
      title: app.t('chooseLanguage'),
      builder: (ctx) {
        Widget option(String code, String label, String font) => ListRow(
              icon: Icons.language_rounded,
              label: label,
              trailing: app.lang == code ? Icon(Icons.check_rounded, size: 20, color: AppColors.ink) : null,
              showChevron: false,
              onTap: () {
                app.setLang(code);
                Navigator.of(ctx).pop();
              },
            );
        return ListGroup(children: [
          option('ar', 'العربية', AppFonts.arabic),
          option('en', 'English', AppFonts.latin),
        ]);
      },
    );
  }

  void _chooseTheme(BuildContext context) {
    final app = context.appRead;
    showAppSheet<void>(
      context,
      title: app.t('appearance'),
      builder: (ctx) {
        Widget option(String mode, IconData icon) => ListRow(
              icon: icon,
              label: app.t('theme${mode[0].toUpperCase()}${mode.substring(1)}'),
              trailing: app.themeMode == mode ? Icon(Icons.check_rounded, size: 20, color: AppColors.ink) : null,
              showChevron: false,
              onTap: () {
                Navigator.of(ctx).pop();
                app.setThemeMode(mode);
              },
            );
        return ListGroup(children: [
          option('system', Icons.brightness_auto_outlined),
          option('light', Icons.light_mode_outlined),
          option('dark', Icons.dark_mode_outlined),
        ]);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Refresh counts (requests / responses) from the backend.
    final app = context.appRead;
    app.refreshUser().catchError((_) {});
    // The level badge next to the name needs the donation count.
    if (app.donations == null) app.loadDonations().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final u = app.user;
    if (u == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(app.t('settings'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),

        // Header card
        AppCard(
          padding: const EdgeInsets.all(14),
          onTap: () => context.toast(app.t('editSoon')),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(formatPhone(u.phone),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontFamily: AppFonts.latin, fontSize: 12.5, color: AppColors.hint)),
              ]),
            ),
            LevelTrophy(donations: app.donations?.length ?? 0),
            const SizedBox(width: 4),
            ForwardChevron(),
          ]),
        ),
        SizedBox(height: 12),

        // Counts
        AppCard(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: IntrinsicHeight(
            child: Row(children: [
              _Count(
                label: app.t('myRequests'),
                value: u.requestsCount,
                onTap: () => ShellScope.of(context).go(Tabs.requests, segment: 0),
              ),
              VerticalDivider(width: 1),
              _Count(
                label: app.t('myResponses'),
                value: u.responsesCount,
                onTap: () => ShellScope.of(context).go(Tabs.requests, segment: 2),
              ),
            ]),
          ),
        ),
        SizedBox(height: 16),

        SectionLabel(app.t('donationsSection')),
        ListGroup(children: [
          ListRow(
            icon: Icons.history_rounded,
            label: app.t('donationRecord'),
            value: '${app.donations?.length ?? 0}',
            valueLatin: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonationHistoryScreen())),
          ),
        ]),
        SizedBox(height: 16),

        SectionLabel(app.t('personalInfo')),
        ListGroup(children: [
          ListRow(icon: Icons.water_drop_outlined, label: app.t('bloodType'), value: u.bloodType.display, valueLatin: true),
          ListRow(icon: Icons.location_on_outlined, label: app.t('city'), value: app.cityName(u.cityId)),
          ListRow(icon: Icons.person_outline_rounded, label: app.t('gender'), value: app.t(u.gender == Gender.female ? 'female' : 'male')),
          ListRow(icon: Icons.cake_outlined, label: app.t('birthDate'), value: formatYmd(u.birthDate), valueLatin: true),
          ListRow(icon: Icons.phone_outlined, label: app.t('phone'), value: formatPhone(u.phone), valueLatin: true),
        ]),
        SizedBox(height: 16),
        SectionLabel(app.t('preferences')),
        ListGroup(children: [
          ListRow(
            icon: Icons.language_rounded,
            label: app.t('language'),
            value: app.lang == 'ar' ? 'العربية' : 'English',
            onTap: () => _chooseLanguage(context),
          ),
          ListRow(
            icon: Icons.contrast_rounded,
            label: app.t('appearance'),
            value: app.t('theme${app.themeMode[0].toUpperCase()}${app.themeMode.substring(1)}'),
            onTap: () => _chooseTheme(context),
          ),
          ListRow(
            icon: Icons.notifications_none_rounded,
            label: app.t('notifications'),
            trailing: Transform.scale(
              scale: .85,
              child: Switch(
                value: app.notificationsOn,
                activeTrackColor: AppColors.red,
                onChanged: (v) {
                  app.setNotifications(v);
                  context.toast(app.t(v ? 'notifOn' : 'notifOff'));
                },
              ),
            ),
          ),
        ]),
        SizedBox(height: 16),
        SectionLabel(app.t('support')),
        ListGroup(children: [
          ListRow(
            icon: Icons.help_outline_rounded,
            label: app.t('help'),
            onTap: () => context.toast(app.t('helpMsg')),
          ),
          ListRow(
            icon: Icons.description_outlined,
            label: app.t('terms'),
            onTap: () => showTermsSheet(context),
          ),
        ]),
        SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () => _confirmLogout(context),
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(app.t('logout'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.redText)),
            ),
          ),
        ),
        SizedBox(height: 28),
        Center(
          child: Column(children: [
            Image.asset('assets/images/logo_drop.png', height: 26),
            SizedBox(height: 6),
            const Wordmark(fontSize: 13, spaced: true),
            const SizedBox(height: 4),
            Text(app.t('designedAround'), style: TextStyle(fontSize: 12, color: AppColors.hint)),
          ]),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, this.onTap});
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$value', style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.hint)),
          ]),
        ),
      );
}
