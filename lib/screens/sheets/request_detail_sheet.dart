import 'package:flutter/material.dart';


import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';

/// Request details. "I can donate" switches the sheet to the eligibility questions.
Future<void> showRequestDetailSheet(BuildContext context, BloodRequest request, {bool startWithResponse = false}) {
  final app = context.appRead;
  return showAppSheet<void>(
    context,
    title: app.t(startWithResponse ? 'eligTitle' : 'postDetails'),
    builder: (_) => _DetailBody(request: request, startWithResponse: startWithResponse),
  );
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.request, required this.startWithResponse});
  final BloodRequest request;
  final bool startWithResponse;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  late bool _answering = widget.startWithResponse;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _answering
          ? _EligibilityForm(key: const ValueKey('elig'), request: widget.request)
          : _details(context),
    );
  }

  Widget _details(BuildContext context) {
    final app = context.app;
    final r = widget.request;
    final user = app.user;
    final canGive = user != null && user.bloodType.canGiveTo(r.bloodType);
    final already = r.myResponse != null;

    // Grows with the text: hospital names can wrap over several lines.
    Widget info(IconData icon, String label, Widget value) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              IconBox(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted))),
              const SizedBox(width: 8),
              value,
            ]),
          ),
        );

    return Column(key: const ValueKey('details'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text('${r.requesterName} · ${app.cityName(r.cityId)} · ${app.timeAgo(r.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        ShareIconButton(request: r),
      ]),
      const SizedBox(height: 10),
      Text(app.t('needs', {'units': r.unitsNeeded, 'bt': bidiIsolate(r.bloodType.display)}),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      if ((r.note ?? '').isNotEmpty) ...[
        const SizedBox(height: 4),
        UserText(r.note!, style: const TextStyle(fontSize: 14, height: 1.7)),
      ],
      const SizedBox(height: 14),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(children: [
          info(Icons.local_hospital_outlined, app.t('hospital'),
              Flexible(child: Text(app.hospitalName(r.hospitalId), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)))),
          if (r.neededAt != null) ...[
            const Divider(),
            info(Icons.schedule_rounded, app.t('neededAt'),
                Flexible(child: Text(formatDateTime(r.neededAt!, app.lang), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)))),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      if (r.mine)
        const SizedBox.shrink()
      else if (already)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(24)),
          child: Text(app.t(r.myResponse == ResponseStatus.ineligible ? 'ineligibleTag' : 'responded'),
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        )
      else if (canGive)
        PrimaryButton(
          label: app.t('canDonate'),
          radius: 999,
          onPressed: () => setState(() => _answering = true),
        )
      else
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
          child: Text(app.t('notMatch', {'bt': user?.bloodType.display ?? ''}),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.muted)),
        ),
    ]);
  }
}

class _EligibilityForm extends StatefulWidget {
  const _EligibilityForm({super.key, required this.request});
  final BloodRequest request;

  @override
  State<_EligibilityForm> createState() => _EligibilityFormState();
}

class _EligibilityFormState extends State<_EligibilityForm> {
  late final Future<List<EligibilityQuestion>> _questions = context.appRead.api.eligibilityQuestions();
  final Map<int, bool> _answers = {};
  bool _sending = false;
  String? _error;

  Future<void> _send(List<EligibilityQuestion> qs) async {
    final app = context.appRead;
    if (_answers.length < qs.length) {
      setState(() => _error = app.t('answerAll'));
      return;
    }
    final user = app.user;
    if (user != null && user.daysUntilEligible > 0) {
      Navigator.of(context).pop();
      context.toast(app.t('cooldown', {'n': user.daysUntilEligible}));
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      final status = await app.api.respond(widget.request.id, _answers);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.toast(app.t(status == ResponseStatus.accepted ? 'responseSent' : 'notEligible'));
      app.refreshUser().catchError((_) {});
    } catch (e) {
      if (mounted) setState(() { _error = app.errorText(e); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return FutureBuilder<List<EligibilityQuestion>>(
      future: _questions,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)));
        }
        if (snap.hasError) {
          return Text(app.errorText(snap.error!), style: TextStyle(color: AppColors.muted));
        }
        final qs = snap.data!;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(app.t('eligSub'), style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 12),
          for (final q in qs) ...[
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Expanded(child: Text(q.text(app.lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: ChoiceTile(
                    label: app.t('yes'),
                    height: 34,
                    selected: _answers[q.id] == true,
                    onTap: () => setState(() { _answers[q.id] = true; _error = null; }),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 60,
                  child: ChoiceTile(
                    label: app.t('no'),
                    height: 34,
                    selected: _answers[q.id] == false,
                    onTap: () => setState(() { _answers[q.id] = false; _error = null; }),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          ErrorText(_error),
          const SizedBox(height: 10),
          PrimaryButton(label: app.t('sendResponse'), loading: _sending, onPressed: () => _send(qs)),
        ]);
      },
    );
  }
}
