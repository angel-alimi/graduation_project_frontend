import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../../widgets/request_card.dart';
import 'contact_sheet.dart';

/// The requester's view of one of their requests: donors who accepted it,
/// with a way to contact each one and confirm their donation.
Future<void> showRespondersSheet(BuildContext context, BloodRequest request) {
  final app = context.appRead;
  return showAppSheet<void>(context, title: app.t('responders'), builder: (_) => _RespondersBody(request));
}

class _RespondersBody extends StatefulWidget {
  const _RespondersBody(this.request);
  final BloodRequest request;

  @override
  State<_RespondersBody> createState() => _RespondersBodyState();
}

class _RespondersBodyState extends State<_RespondersBody> {
  late Future<List<Responder>> _future = _fetch();

  /// Responses being confirmed right now (shows a spinner on that card).
  final Set<int> _busy = {};

  /// Local copy so a confirmation updates the card without reloading the list.
  List<Responder>? _list;

  Future<List<Responder>> _fetch() async {
    final list = await context.appRead.api.responders(widget.request.id);
    _list = list;
    return list;
  }

  void _reload() => setState(() { _list = null; _future = _fetch(); });

  Future<void> _confirm(Responder d) async {
    final app = context.appRead;
    final ok = await _confirmDialog(context, d.donorName);
    if (ok != true || !mounted) return;
    setState(() => _busy.add(d.id));
    try {
      final updated = await app.api.confirmDonation(widget.request.id, d.id);
      if (!mounted) return;
      setState(() {
        _busy.remove(d.id);
        final i = _list?.indexWhere((x) => x.id == d.id) ?? -1;
        if (i >= 0) _list![i] = updated;
      });
      context.toast(app.t('confirmedToast', {'name': d.donorName}));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(d.id));
      context.toast(app.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final r = widget.request;
    return FutureBuilder<List<Responder>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)));
        }
        if (snap.hasError) {
          return SizedBox(height: 220, child: ErrorState(message: app.errorText(snap.error!), onRetry: _reload));
        }
        final list = _list ?? snap.data ?? const <Responder>[];
        final confirmed = list.where((d) => d.confirmed).length;

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Summary(request: r, confirmed: confirmed),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(title: app.t('noResponders'), subtitle: app.t('noRespondersSub'), pose: MascotPose.phone),
            )
          else ...[
            Text(app.t('respondersSub'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64),
                  _ResponderRow(
                    donor: list[i],
                    busy: _busy.contains(list[i].id),
                    onContact: () => showDonorContactSheet(context, list[i]),
                    onConfirm: () => _confirm(list[i]),
                  ),
                ],
              ]),
            ),
          ],
        ]);
      },
    );
  }
}

/// The request at a glance: blood tag, patient and hospital, and confirmed units so far.
class _Summary extends StatelessWidget {
  const _Summary({required this.request, required this.confirmed});
  final BloodRequest request;
  final int confirmed;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final r = request;
    final total = r.unitsNeeded;
    final shown = confirmed > total ? total : confirmed;
    final title = r.patientName ?? app.user?.fullName ?? r.requesterName;
    return AppCard(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: userTextDirection(title),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              BloodLabel(r.bloodType),
            ]),
            Text(app.hospitalName(r.hospitalId),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.hint)),
            const SizedBox(height: 10),
            // One segment per unit: filled once that donation is confirmed.
            Row(children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < shown ? AppColors.red : AppColors.field,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 5),
            Text(app.t('unitsConfirmed', {'n': shown, 't': total}),
                style: TextStyle(fontSize: 11.5, color: AppColors.hint)),
          ]),
        ),
      ]),
    );
  }
}

/// One donor row: avatar, name, city / time / type, a call button and Confirm.
class _ResponderRow extends StatelessWidget {
  const _ResponderRow({required this.donor, required this.busy, required this.onContact, required this.onConfirm});
  final Responder donor;
  final bool busy;
  final VoidCallback onContact;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final d = donor;
    final name = d.donorName.trim();
    final initial = name.isEmpty ? '?' : name.characters.first;

    final Widget trailing;
    if (d.confirmed) {
      trailing = SoftButton(key: const ValueKey('done'), label: app.t('donationConfirmed'), icon: Icons.check_rounded, done: true);
    } else if (busy) {
      trailing = const SizedBox(
        key: ValueKey('busy'),
        width: 72,
        height: 34,
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))),
      );
    } else {
      trailing = AcceptButton(key: const ValueKey('confirm'), label: app.t('confirm'), onPressed: onConfirm);
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      child: Row(children: [
        // Avatar; a small red drop marks donors whose donation is confirmed.
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
              child: Text(initial, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            if (d.confirmed)
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Icons.water_drop_rounded, size: 9, color: Colors.white),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: userTextDirection(name),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              BloodLabel(d.bloodType, size: 12),
            ]),
            const SizedBox(height: 2),
            Text('${app.cityName(d.cityId)} · ${app.timeAgo(d.respondedAt)}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppColors.hint)),
          ]),
        ),
        const SizedBox(width: 8),
        SquareIconButton(icon: Icons.phone_outlined, size: 34, filled: true, tooltip: app.t('contactDonor'), onPressed: onContact),
        const SizedBox(width: 6),
        AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: trailing),
      ]),
    );
  }
}

/// Asks the requester to confirm the donation really happened. True on "Yes, they donated".
Future<bool?> _confirmDialog(BuildContext context, String name) {
  final app = context.appRead;
  final label = Theme.of(context).textTheme.labelLarge!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(app.t('confirmDonationQ', {'name': name}), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(app.t('confirmDonationBody'), style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.muted)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              textStyle: label.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text(app.t('confirmYes')),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: AppColors.muted,
              shape: const StadiumBorder(),
              textStyle: label.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: Text(app.t('cancel')),
          ),
        ]),
      ),
    ),
  );
}
