import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/common.dart';
import 'notifications_screen.dart';
import 'sheets/new_request_sheet.dart';
import 'tabs/feed_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/requests_tab.dart';

/// Bottom bar slots, in order. Slot 2 (the red "+", new request) is a button, not a tab.
class Tabs {
  /// Home: my requests and matched requests.
  static const requests = 0;
  static const feed = 1;
  static const newRequest = 2;
  static const notifications = 3;

  /// Settings (profile, preferences, support).
  static const settings = 4;
}

/// Lets any screen switch tabs (e.g. a notification opens Matched requests).
class ShellController extends ChangeNotifier {
  int index = Tabs.requests;
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
  const ShellScope(
      {super.key, required ShellController controller, required super.child})
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

  @override
  void initState() {
    super.initState();
    // Opening the notifications tab clears the unread dot.
    _shell.addListener(() {
      if (_shell.index == Tabs.notifications && _unread) {
        setState(() => _unread = false);
      }
    });
  }

  /// The red "+": opens the new request form, then shows My requests.
  Future<void> _newRequest() async {
    final created = await showNewRequestSheet(context);
    if (created == true && mounted) {
      _shell.go(Tabs.requests, segment: 0);
      _shell.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ShellScope(
      controller: _shell,
      child: ListenableBuilder(
        listenable: _shell,
        builder: (context, _) {
          final tabs = <int, Widget>{
            Tabs.requests: const RequestsTab(),
            Tabs.feed: const FeedTab(),
            Tabs.notifications: const NotificationsTab(),
            Tabs.settings: const ProfileTab()
          };
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(children: [
                // Header: logo (notifications are in the bottom bar)
                Container(
                  height: 54,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: AppColors.line))),
                  // Fixed left-to-right so the logo never moves with the language.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: BrandRow(),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position:
                            Tween(begin: Offset(0, .015), end: Offset.zero)
                                .animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                        key: ValueKey(_shell.index),
                        child: tabs[_shell.index]!),
                  ),
                ),
              ]),
            ),
            bottomNavigationBar: LifeShareBottomBar(
              index: _shell.index,
              onTap: (i) => _shell.go(i),
              items: [
                BottomBarItem(Icons.home_outlined, app.t('tHome')),
                BottomBarItem(Icons.article_outlined, app.t('tFeed')),
                BottomBarItem.action(
                    Icons.add_rounded, app.t('newRequest'), _newRequest,
                    primary: true),
                BottomBarItem(
                    Icons.notifications_none_rounded, app.t('notifications'),
                    badge: _unread && app.notificationsOn),
                BottomBarItem(Icons.settings_outlined, app.t('tSettings')),
              ],
            ),
          );
        },
      ),
    );
  }
}
