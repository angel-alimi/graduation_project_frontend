import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/common.dart';
import 'notifications_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/feed_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/requests_tab.dart';
import 'tabs/settings_tab.dart';

/// Tab indexes, in the order they appear in the bottom bar.
class Tabs {
  static const requests = 0, feed = 1, home = 2, profile = 3, settings = 4;
}

/// Lets any tab switch tabs (e.g. "Donate blood" on the dashboard opens Matched requests).
class ShellController extends ChangeNotifier {
  int index = Tabs.home;
  int requestsSegment = 0; // 0 = mine, 1 = matched
  int refreshTick = 0;

  void go(int tab, {int? segment}) {
    index = tab;
    if (segment != null) requestsSegment = segment;
    notifyListeners();
  }

  /// Ask the visible lists to reload (after creating a request, etc.).
  void refresh() {
    refreshTick++;
    notifyListeners();
  }
}

class ShellScope extends InheritedNotifier<ShellController> {
  const ShellScope({super.key, required ShellController controller, required super.child})
      : super(notifier: controller);

  static ShellController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()!.notifier!;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _shell = ShellController();
  bool _unread = true;

  @override
  void dispose() {
    _shell.dispose();
    super.dispose();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(shell: _shell)));
    if (mounted) setState(() => _unread = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ShellScope(
      controller: _shell,
      child: ListenableBuilder(
        listenable: _shell,
        builder: (context, _) {
          const tabs = [RequestsTab(), FeedTab(), DashboardTab(), ProfileTab(), SettingsTab()];
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(children: [
                // Header: logo, language, notifications
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                  child: Row(children: [
                    const BrandRow(),
                    const Spacer(),
                    _HeaderButton(
                      onTap: app.toggleLang,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.language_rounded, size: 16, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text(app.lang == 'ar' ? 'EN' : 'ع',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: app.lang == 'ar' ? AppFonts.latin : AppFonts.arabic)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    SquareIconButton(
                      icon: Icons.notifications_none_rounded,
                      size: 36,
                      filled: true,
                      badge: _unread && app.notificationsOn,
                      tooltip: app.t('notifications'),
                      onPressed: _openNotifications,
                    ),
                  ]),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, .015), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey(_shell.index), child: tabs[_shell.index]),
                  ),
                ),
              ]),
            ),
            bottomNavigationBar: LifeShareBottomBar(
              index: _shell.index,
              onTap: (i) => _shell.go(i),
              items: [
                BottomBarItem(Icons.assignment_outlined, app.t('tRequests')),
                BottomBarItem(Icons.home_outlined, app.t('tFeed')),
                BottomBarItem(Icons.grid_view_rounded, app.t('tHome')),
                BottomBarItem(Icons.person_outline_rounded, app.t('tProfile')),
                BottomBarItem(Icons.tune_rounded, app.t('tSettings')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 10), alignment: Alignment.center, child: child),
        ),
      );
}
