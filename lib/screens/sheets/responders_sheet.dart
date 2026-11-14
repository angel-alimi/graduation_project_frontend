import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';
import 'contact_sheet.dart';

/// The requester's view of one of their requests: donors who accepted it,
/// with a way to contact each one and confirm their donation.
Future<void> showRespondersSheet(BuildContext context, BloodRequest request) {
  final app = context.appRead;
  return showAppSheet<void>(context,
      title: app.t('responders'), builder: (_) => _RespondersBody(request));
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

  void _reload() => setState(() {
        _list = null;
        _future = _fetch();
      });

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
          return const SizedBox(
              height: 200,
              child:
                  Center(child: CircularProgressIndicator(strokeWidth: 2.4)));
        }
        if (snap.hasError) {
          return SizedBox(
              height: 220,
              child: ErrorState(
                  message: app.errorText(snap.error!), onRetry: _reload));
        }
        final list = _list ?? snap.data ?? const <Responder>[];
        final confirmed = list.where((d) => d.confirmed).length;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Summary(request: r, confirmed: confirmed),
              const SizedBox(height: 14),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: EmptyState(
                      title: app.t('noResponders'),
                      subtitle: app.t('noRespondersSub'),
                      icon: Icons.people_outline_rounded),
                )
              else ...[
                Text(app.t('respondersSub'),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (var i = 0; i < list.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 64),
                      _ResponderRow(
                        donor: list[i],
                        busy: _busy.contains(list[i].id),
                        onContact: () =>
                            showDonorContactSheet(context, list[i]),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: userTextDirection(title),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              BloodTypeTag(r.bloodType, small: true),
            ]),
            Text(app.hospitalName(r.hospitalId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.hint)),
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
  const _ResponderRow(
      {required this.donor,
      required this.busy,
      required this.onContact,
      required this.onConfirm});
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

    final Widget confirm;
    if (d.confirmed) {
      confirm = SoftButton(
          key: const ValueKey('done'),
          label: app.t('donationConfirmed'),
          icon: Icons.check_rounded,
          done: true);
    } else if (busy) {
      confirm = const SizedBox(
        key: ValueKey('busy'),
        height: 38,
        child: Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2))),
      );
    } else {
      confirm = AcceptButton(
          key: const ValueKey('confirm'),
          label: app.t('confirm'),
          onPressed: onConfirm);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: AppColors.soft, shape: BoxShape.circle),
            child: Text(initial,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: userTextDirection(name),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${app.cityName(d.cityId)} · ${app.timeAgo(d.respondedAt)}',
                  style: TextStyle(fontSize: 12, color: AppColors.hint)),
            ]),
          ),
          const SizedBox(width: 8),
          BloodTypeTag(d.bloodType, small: true),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: SoftButton(
                label: app.t('call'),
                icon: Icons.phone_outlined,
                onPressed: onContact),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              // Stretch the current button to the full half-width.
              layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.passthrough,
                  children: [...previous, if (current != null) current]),
              child: confirm,
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Asks the requester to confirm the donation really happened. True on "Yes, they donated".
Future<bool?> _confirmDialog(BuildContext context, String name) {
  final app = context.appRead;
  return showConfirmDialog(
    context,
    title: app.t('confirmDonationQ', {'name': name}),
    message: app.t('confirmDonationBody'),
    confirmLabel: app.t('confirmYes'),
  );
}
