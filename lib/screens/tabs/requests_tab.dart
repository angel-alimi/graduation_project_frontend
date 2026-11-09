import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../../widgets/request_card.dart';
import '../home_shell.dart';
import '../sheets/contact_sheet.dart';
import '../sheets/request_detail_sheet.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  Future<List<BloodRequest>>? _future;
  int _segment = 0;
  int _tick = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = ShellScope.of(context);
    if (_future == null || shell.requestsSegment != _segment || shell.refreshTick != _tick) {
      _segment = shell.requestsSegment;
      _tick = shell.refreshTick;
      _future = _fetch(); // no setState here: build runs right after
    }
  }

  Future<List<BloodRequest>> _fetch() {
    final api = context.appRead.api;
    return _segment == 0 ? api.myRequests() : api.matchedRequests();
  }

  void _load() => setState(() => _future = _fetch());

  Future<void> _cancel(BloodRequest r) async {
    final app = context.appRead;
    try {
      await app.api.cancelRequest(r.id);
      if (!mounted) return;
      context.toast(app.t('cancelled'));
      _load();
      app.refreshUser().catchError((_) {});
    } catch (e) {
      if (mounted) context.toast(app.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final shell = ShellScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(app.t('requests'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        _Segmented(
          value: _segment,
          labels: [app.t('mine'), app.t('matched')],
          onChanged: (v) => shell.go(Tabs.requests, segment: v),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: FutureBuilder<List<BloodRequest>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
              }
              if (snap.hasError) return ErrorState(message: app.errorText(snap.error!), onRetry: _load);
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return _segment == 0
                    ? EmptyState(title: app.t('emptyMine'), subtitle: app.t('emptyMineSub'))
                    : EmptyState(title: app.t('emptyMatch'), subtitle: app.t('emptyMatchSub'), pose: MascotPose.phone);
              }
              return RefreshIndicator(
                color: AppColors.red,
                onRefresh: () async => _load(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: list.length + (_segment == 1 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (_segment == 1 && i == 0) {
                      return Text(app.t('matchNote', {'bt': app.user?.bloodType.display ?? ''}),
                          style: Theme.of(context).textTheme.bodySmall);
                    }
                    final r = list[_segment == 1 ? i - 1 : i];
                    if (_segment == 0) {
                      return RequestCard(
                        request: r,
                        action: SoftButton(
                          label: app.t('cancelRequest'),
                          destructive: true,
                          onPressed: () => _cancel(r),
                        ),
                      );
                    }
                    final done = r.myResponse != null;
                    return RequestCard(
                      request: r,
                      onTap: () => showRequestDetailSheet(context, r).then((_) => _load()),
                      action: Row(mainAxisSize: MainAxisSize.min, children: [
                        SoftButton(
                          label: app.t('contact'),
                          onPressed: () => showContactSheet(context, r),
                        ),
                        const SizedBox(width: 8),
                        done
                            ? SoftButton(
                                label: app.t(r.myResponse == ResponseStatus.ineligible ? 'ineligibleTag' : 'responded'),
                                done: true,
                              )
                            : AcceptButton(
                                label: app.t('canDonate'),
                                onPressed: () => showRequestDetailSheet(context, r, startWithResponse: true).then((_) => _load()),
                              ),
                      ]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Two-option segmented control with a sliding white knob.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.labels, required this.onChanged});
  final int value;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
      child: Stack(children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 380),
          curve: const Cubic(.34, 1.2, .64, 1),
          alignment: value == 0 ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
          child: FractionallySizedBox(
            widthFactor: .5,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
        Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 13,
                          fontWeight: i == value ? FontWeight.w800 : FontWeight.w400,
                          color: i == value ? AppColors.ink : AppColors.muted,
                        ),
                    child: Text(labels[i]),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}
