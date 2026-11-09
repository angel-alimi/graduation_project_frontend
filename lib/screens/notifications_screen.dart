import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import 'home_shell.dart';

/// Full-screen notifications list.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.shell});
  final ShellController shell;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future = context.appRead.api.notifications();

  void _reload() => setState(() => _future = context.appRead.api.notifications());

  Future<void> _markAll() async {
    final app = context.appRead;
    try {
      await app.api.markAllNotificationsRead();
      _reload();
    } catch (e) {
      if (mounted) context.toast(app.errorText(e));
    }
  }

  void _open(AppNotification n) {
    switch (n.type) {
      case NotificationType.match:
        widget.shell.go(Tabs.requests, segment: 1);
        break;
      case NotificationType.requestPosted:
        widget.shell.go(Tabs.requests, segment: 0);
        break;
      case NotificationType.reminder:
      case NotificationType.welcome:
        widget.shell.go(Tabs.home);
        break;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const BackSquareButton(),
              const SizedBox(width: 12),
              Expanded(child: Text(app.t('notifications'), style: Theme.of(context).textTheme.titleLarge)),
              TextButton(onPressed: _markAll, child: Text(app.t('markAllRead'))),
            ]),
            const SizedBox(height: 10),
            if (!app.notificationsOn)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
                child: Text(app.t('notifsOffBanner'), style: const TextStyle(fontSize: 12)),
              ),
            Expanded(
              child: FutureBuilder<List<AppNotification>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
                  }
                  if (snap.hasError) return ErrorState(message: app.errorText(snap.error!), onRetry: _reload);
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return EmptyState(title: app.t('emptyNotifs'), subtitle: app.t('nWelcomeB'), pose: MascotPose.phone);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) => _NotificationTile(n: list[i], onTap: () => _open(list[i])),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final bt = n.bloodType?.display ?? '';
    final hospital = n.hospitalId == null ? '' : app.hospitalName(n.hospitalId!);

    late final IconData icon;
    late final Color bg, fg;
    late final String title, body;
    switch (n.type) {
      case NotificationType.match:
        icon = Icons.water_drop_outlined; bg = AppColors.soft; fg = AppColors.red;
        title = app.t('nMatch');
        body = app.t('nMatchB', {'name': n.personName ?? '', 'bt': bt, 'hospital': hospital});
        break;
      case NotificationType.requestPosted:
        icon = Icons.assignment_turned_in_outlined; bg = AppColors.greenBg; fg = AppColors.green;
        title = app.t('nPosted');
        body = app.t('nPostedB', {'bt': bt, 'hospital': hospital});
        break;
      case NotificationType.reminder:
        icon = Icons.event_outlined; bg = AppColors.amberBg; fg = AppColors.amber;
        title = app.t('nReminder');
        body = app.t('nReminderB');
        break;
      case NotificationType.welcome:
        icon = Icons.favorite_border_rounded; bg = AppColors.indigoBg; fg = AppColors.indigo;
        title = app.t('nWelcome');
        body = app.t('nWelcomeB');
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBox(icon, size: 40, bg: bg, fg: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.muted)),
              const SizedBox(height: 3),
              Text(app.timeAgo(n.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.hint)),
            ]),
          ),
          if (!n.read)
            Container(
              margin: const EdgeInsetsDirectional.only(start: 8, top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }
}
