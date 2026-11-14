import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';
import '../home_shell.dart';
import '../sheets/contact_sheet.dart';
import '../sheets/request_detail_sheet.dart';
import '../sheets/responders_sheet.dart';

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
    return switch (_segment) {
      0 => api.myRequests(),
      1 => api.matchedRequests(),
      _ => api.acceptedRequests(),
    };
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
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(app.t('requests'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _Segmented(
              value: _segment,
              labels: [app.t('mine'), app.t('matched'), app.t('acceptedTab')],
              onChanged: (v) => shell.go(Tabs.requests, segment: v),
            ),
          ]),
        ),
        const SizedBox(height: 10),
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
                return switch (_segment) {
                  0 => EmptyState(title: app.t('emptyMine'), subtitle: app.t('emptyMineSub'), icon: Icons.assignment_outlined),
                  1 => EmptyState(title: app.t('emptyMatch'), subtitle: app.t('emptyMatchSub'), icon: Icons.bloodtype_outlined),
                  _ => EmptyState(title: app.t('emptyAccepted'), subtitle: app.t('emptyAcceptedSub'), icon: Icons.volunteer_activism_outlined),
                };
              }
              return RefreshIndicator(
                color: AppColors.redText,
                onRefresh: () async => _load(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length + (_segment == 1 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (_segment == 1 && i == 0) {
                      return Text(app.t('matchNote', {'bt': app.user?.bloodType.display ?? ''}),
                          style: Theme.of(context).textTheme.bodySmall);
                    }
                    final r = list[_segment == 1 ? i - 1 : i];
                    if (_segment == 0) {
                      final open = r.status == RequestStatus.open;
                      void openResponders() => showRespondersSheet(context, r).then((_) => _load());
                      return RequestCard(
                        request: r,
                        onTap: openResponders,
                        menu: [
                          if (open)
                            PostAction(
                              icon: Icons.close_rounded,
                              label: app.t('cancelRequest'),
                              destructive: true,
                              onTap: () => _cancel(r),
                            ),
                        ],
                        actions: [
                          if (!open)
                            PostAction(icon: Icons.check_circle_outline_rounded, label: app.t('fulfilled'), done: true),
                          PostAction(
                            icon: Icons.people_outline_rounded,
                            label: app.t('responders'),
                            count: r.respondersCount,
                            primary: true,
                            onTap: openResponders,
                          ),
                        ],
                      );
                    }
                    if (_segment == 2) {
                      // Accepted: where things stand, plus Contact while the request is open.
                      final String status;
                      if (r.status == RequestStatus.cancelled) {
                        status = app.t('reqCancelled');
                      } else if (r.myResponse == ResponseStatus.completed) {
                        status = app.t('donationConfirmed');
                      } else if (r.status == RequestStatus.fulfilled) {
                        status = app.t('reqFulfilled');
                      } else {
                        status = app.t('responded');
                      }
                      return RequestCard(
                        request: r,
                        onTap: () => showRequestDetailSheet(context, r).then((_) => _load()),
                        actions: [
                          PostAction(label: status, done: true),
                          if (r.status == RequestStatus.open)
                            PostAction(
                              icon: Icons.call_outlined,
                              label: app.t('contact'),
                              onTap: () => showContactSheet(context, r),
                            ),
                        ],
                      );
                    }
                    final done = r.myResponse != null;
                    return RequestCard(
                      request: r,
                      onTap: () => showRequestDetailSheet(context, r).then((_) => _load()),
                      actions: [
                        done
                            ? PostAction(
                                icon: Icons.check_circle_outline_rounded,
                                label: app.t(r.myResponse == ResponseStatus.ineligible ? 'ineligibleTag' : 'responded'),
                                done: true,
                              )
                            : PostAction(
                                label: app.t('canDonate'),
                                primary: true,
                                onTap: () => showRequestDetailSheet(context, r, startWithResponse: true).then((_) => _load()),
                              ),
                        PostAction(
                          icon: Icons.call_outlined,
                          label: app.t('contact'),
                          onTap: () => showContactSheet(context, r),
                        ),
                      ],
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

/// Segmented control with a sliding white knob (any number of options).
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
          alignment: AlignmentDirectional(labels.length < 2 ? -1 : -1 + 2 * value / (labels.length - 1), 0),
          child: FractionallySizedBox(
            widthFactor: 1 / labels.length,
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
