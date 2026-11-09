import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../welcome_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final app = context.appRead;
    final yes = await showAppSheet<bool>(
      context,
      title: app.t('logoutQ'),
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(app.t('logoutSub'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(app.t('cancel')))),
          const SizedBox(width: 12),
          Expanded(child: PrimaryButton(label: app.t('logout'), onPressed: () => Navigator.of(ctx).pop(true))),
        ]),
      ]),
    );
    if (yes != true || !context.mounted) return;
    await app.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    Widget row({required IconData icon, required String label, required Widget trailing, VoidCallback? onTap, Color? color}) => InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(children: [
              IconBox(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
              trailing,
            ]),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(app.t('settings'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        SectionLabel(app.t('preferences')),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            row(icon: Icons.language_rounded, label: app.t('language'), trailing: const LangToggle()),
            const Divider(),
            row(
              icon: Icons.notifications_none_rounded,
              label: app.t('notifications'),
              trailing: Switch(
                value: app.notificationsOn,
                activeTrackColor: AppColors.red,
                onChanged: (v) {
                  app.setNotifications(v);
                  context.toast(app.t(v ? 'notifOn' : 'notifOff'));
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionLabel(app.t('support')),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: row(
            icon: Icons.help_outline_rounded,
            label: app.t('help'),
            trailing: const ForwardChevron(),
            onTap: () => context.toast(app.t('helpMsg')),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: row(
            icon: Icons.logout_rounded,
            label: app.t('logout'),
            color: AppColors.red,
            trailing: const SizedBox.shrink(),
            onTap: () => _confirmLogout(context),
          ),
        ),
        const SizedBox(height: 26),
        Center(
          child: Column(children: [
            Image.asset('assets/images/logo_drop.png', height: 30),
            const SizedBox(height: 6),
            const Wordmark(fontSize: 14, spaced: true),
            const SizedBox(height: 4),
            Text(app.t('designedAround'), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ],
    );
  }
}
