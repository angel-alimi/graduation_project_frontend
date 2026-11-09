import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Lets the user record the date of their last donation (drives the 56-day cooldown).
Future<void> showUpdateDonationSheet(BuildContext context) {
  final app = context.appRead;
  return showAppSheet<void>(context, title: app.t('updateDonation'), builder: (_) => const _Body());
}

class _Body extends StatefulWidget {
  const _Body();
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late DateTime? _date = context.appRead.user?.lastDonationDate;
  bool _saving = false;
  String? _error;

  Future<void> _pick() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: context.appRead.user?.birthDate ?? DateTime(now.year - 70),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final app = context.appRead;
    if (_date == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      final u = await app.api.updateLastDonation(_date!);
      app.setUser(u);
      if (!mounted) return;
      Navigator.of(context).pop();
      final passed = DateTime.now().difference(_date!).inDays;
      final left = AppConfig.donationCooldownDays - passed;
      context.toast(left > 0 ? app.t('cooldown', {'n': left}) : app.t('eligibleNow'));
    } catch (e) {
      if (mounted) setState(() { _error = app.errorText(e); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldLabel(app.t('lastDonationDate')),
      InkWell(
        onTap: _pick,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted)),
          child: Text(
            _date == null ? app.t('pickDate') : formatYmd(_date!),
            style: TextStyle(fontSize: 14, color: _date == null ? AppColors.hint : AppColors.ink, fontFamily: _date == null ? null : AppFonts.latin),
          ),
        ),
      ),
      ErrorText(_error),
      const SizedBox(height: 16),
      PrimaryButton(label: app.t('save'), loading: _saving, onPressed: _date == null ? null : _save),
    ]);
  }
}
