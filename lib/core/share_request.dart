import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/inputs.dart';

/// The message sent when a request is shared, in the app's current language.
String requestShareText(AppState app, BloodRequest r) {
  final bt = r.bloodType.display;
  final phones = r.allPhones.map(formatPhone).join('  /  ');
  return [
    app.t('shareHead', {'bt': bt}),
    '',
    r.requesterName,
    app.t('shareBody', {
      'units': r.unitsNeeded,
      'bt': bt,
      'hospital': app.hospitalName(r.hospitalId),
      'city': app.cityName(r.cityId),
    }),
    if (r.neededAt != null) app.t('shareWhen', {'d': formatDateTime(r.neededAt!, app.lang)}),
    if ((r.note ?? '').trim().isNotEmpty) app.t('shareNote', {'n': r.note!.trim()}),
    if (phones.isNotEmpty) app.t('shareContact', {'p': phones}),
    '',
    app.t('shareFooter'),
  ].join('\n');
}

/// Opens the phone's share sheet (WhatsApp, Messages, Telegram, email…) with the request as text.
Future<void> shareRequest(BuildContext context, BloodRequest r) async {
  final app = context.appRead;
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    text: requestShareText(app, r),
    subject: app.t('shareSubject'),
    // Needed on iPad so the sheet knows where to point.
    sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}
