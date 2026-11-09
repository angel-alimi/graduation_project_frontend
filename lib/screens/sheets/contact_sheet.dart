import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';

/// Bottom sheet with the requester's number and ways to reach them:
/// call, SMS or WhatsApp. Styled like a phone's contact card.
Future<void> showContactSheet(BuildContext context, BloodRequest request) {
  final app = context.appRead;
  return showAppSheet<void>(context, title: app.t('contactTitle'), builder: (_) => _ContactBody(request));
}

class _ContactBody extends StatefulWidget {
  const _ContactBody(this.r);
  final BloodRequest r;

  @override
  State<_ContactBody> createState() => _ContactBodyState();
}

class _ContactBodyState extends State<_ContactBody> {
  /// Which of the requester's numbers the actions use.
  int _selected = 0;

  BloodRequest get r => widget.r;

  /// International form without "+", e.g. 970591234567.
  String _intl(String local) => '970${normalizePhone(local)}';

  Future<void> _open(BuildContext context, Uri uri) async {
    final app = context.appRead;
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) context.toast(app.t('cantOpen'));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final phones = r.allPhones;
    final hasPhone = phones.isNotEmpty;
    final phone = hasPhone ? phones[_selected.clamp(0, phones.length - 1)] : '';

    final header = Column(children: [
      Text(r.requesterName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      if (phones.length == 1) ...[
        const SizedBox(height: 2),
        Text(formatPhone(phone),
            textDirection: TextDirection.ltr,
            style: TextStyle(fontFamily: AppFonts.latin, fontSize: 14, color: AppColors.muted)),
      ],
      // Several numbers: pick one, the actions below use it.
      if (phones.length > 1) ...[
        const SizedBox(height: 12),
        for (var i = 0; i < phones.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          ChoiceTile(
            label: formatPhone(phones[i]),
            latinFont: true,
            height: 44,
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
          ),
        ],
      ],
    ]);

    if (!hasPhone) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        const SizedBox(height: 16),
        Text(app.t('noPhone'), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.muted)),
      ]);
    }

    final message = app.t('smsBody', {'name': r.requesterName});
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header,
      const SizedBox(height: 18),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _Row(
            icon: Icons.phone_outlined,
            label: app.t('call'),
            onTap: () => _open(context, Uri(scheme: 'tel', path: '+${_intl(phone)}')),
          ),
          const Divider(height: 1, indent: 52),
          _Row(
            icon: Icons.textsms_outlined,
            label: app.t('sms'),
            onTap: () => _open(context, Uri(scheme: 'sms', path: '+${_intl(phone)}', queryParameters: {'body': message})),
          ),
          const Divider(height: 1, indent: 52),
          _Row(
            icon: Icons.chat_bubble_outline_rounded,
            label: app.t('whatsapp'),
            onTap: () => _open(context, Uri.https('wa.me', '/${_intl(phone)}', {'text': message})),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Text(app.t('contactNote'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

/// A plain list row: thin grey icon, label, nothing else.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(children: [
            const SizedBox(width: 16),
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink))),
          ]),
        ),
      );
}
