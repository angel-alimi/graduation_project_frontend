import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../core/search.dart';
import '../../widgets/common.dart';
import '../../widgets/search_picker.dart';

/// Opens the "New blood request" form. Returns true when a request was posted.
Future<bool?> showNewRequestSheet(BuildContext context) {
  final app = context.appRead;
  return showAppSheet<bool>(context, title: app.t('newRequestTitle'), builder: (_) => const _NewRequestForm());
}

class _NewRequestForm extends StatefulWidget {
  const _NewRequestForm();

  @override
  State<_NewRequestForm> createState() => _NewRequestFormState();
}

class _NewRequestFormState extends State<_NewRequestForm> {
  final _patient = TextEditingController();
  final _note = TextEditingController();
  late BloodType _type = context.appRead.user?.bloodType ?? BloodType.oPos;
  int _units = 1;
  int? _hospitalId;
  Urgency _urgency = Urgency.normal;
  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;
  String? _error, _eHospital, _eNeeded;

  /// How far ahead a request can be scheduled.
  static const _maxDaysAhead = 90;

  DateTime? get _neededAt {
    final d = _date, t = _time;
    return d == null || t == null ? null : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  /// An error when the chosen moment has passed. Nothing while a part is still missing.
  String? _pastError(AppState app) {
    final at = _neededAt;
    return at != null && !at.isAfter(DateTime.now()) ? app.t('eNeededPast') : null;
  }

  Future<void> _pickDate() async {
    final app = context.appRead;
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null && !_date!.isBefore(today) ? _date! : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: _maxDaysAhead)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && mounted) {
      setState(() { _date = picked; _eNeeded = _pastError(app); });
    }
  }

  Future<void> _pickTime() async {
    final app = context.appRead;
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );
    if (picked != null && mounted) {
      setState(() { _time = picked; _eNeeded = _pastError(app); });
    }
  }

  @override
  void initState() {
    super.initState();
    context.appRead.ensureLookups().catchError((_) {});
  }

  /// The user's city first, then alphabetical.
  List<PickerOption<int>> _hospitalOptions(AppState app) {
    final userCity = app.user?.cityId;
    final list = app.hospitals.toList()
      ..sort((a, b) {
        final aHome = a.cityId == userCity, bHome = b.cityId == userCity;
        if (aHome != bHome) return aHome ? -1 : 1;
        return compareForSearch(a.name(app.lang), b.name(app.lang));
      });
    return [
      for (final h in list)
        PickerOption(
          value: h.id,
          label: h.name(app.lang),
          subtitle: app.cityName(h.cityId),
          searchText: '${h.nameAr} ${h.nameEn} ${_cityNames(app, h.cityId)}',
        ),
    ];
  }

  String _cityNames(AppState app, int cityId) {
    for (final c in app.cities) {
      if (c.id == cityId) return '${c.nameAr} ${c.nameEn}';
    }
    return '';
  }

  @override
  void dispose() {
    _patient.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.appRead;
    final neededAt = _neededAt;
    setState(() {
      _eHospital = _hospitalId == null ? app.t('eHospital') : null;
      _eNeeded = neededAt == null ? app.t('eNeededAt') : _pastError(app);
    });
    if (_eHospital != null || _eNeeded != null) return;
    setState(() { _loading = true; _error = null; });
    try {
      await app.api.createRequest(NewRequest(
        patientName: _patient.text,
        bloodType: _type,
        unitsNeeded: _units,
        hospitalId: _hospitalId!,
        urgency: _urgency,
        neededAt: neededAt!,
        note: _note.text,
      ));
      if (!mounted) return;
      app.refreshUser().catchError((_) {});
      Navigator.of(context).pop(true);
      context.toast(app.t('posted'));
    } catch (e) {
      if (mounted) setState(() { _error = app.errorText(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    Widget stepBtn(IconData icon, VoidCallback? onTap) => SquareIconButton(icon: icon, size: 40, onPressed: onTap);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldLabel(app.t('patientName'), optional: true),
      TextField(controller: _patient),
      const SizedBox(height: 14),
      FieldLabel(app.t('neededType')),
      BloodTypeGrid(value: _type, onChanged: (b) => setState(() => _type = b)),
      const SizedBox(height: 14),
      FieldLabel(app.t('unitsNeeded')),
      Row(children: [
        stepBtn(Icons.remove_rounded, _units > 1 ? () => setState(() => _units--) : null),
        SizedBox(
          width: 40,
          child: Text('$_units',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        stepBtn(Icons.add_rounded, _units < 10 ? () => setState(() => _units++) : null),
      ]),
      const SizedBox(height: 14),
      FieldLabel(app.t('hospital')),
      SearchPickerField<int>(
        value: _hospitalId,
        hint: app.t('pickHospital'),
        searchHint: app.t('searchHospital'),
        errorText: _eHospital,
        options: _hospitalOptions(app),
        onChanged: (v) => setState(() { _hospitalId = v; _eHospital = null; }),
      ),
      const SizedBox(height: 14),
      FieldLabel(app.t('neededAt')),
      Row(children: [
        Expanded(
          flex: 3,
          child: _PickerBox(
            text: _date == null ? null : formatDate(_date!, app.lang),
            hint: app.t('pickDate'),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _PickerBox(
            text: _time == null ? null : formatTime(_time!.hour, _time!.minute, app.lang),
            hint: app.t('pickTime'),
            icon: Icons.access_time_rounded,
            onTap: _pickTime,
          ),
        ),
      ]),
      ErrorText(_eNeeded),
      const SizedBox(height: 14),
      FieldLabel(app.t('urgency')),
      Row(children: [
        Expanded(child: ChoiceTile(label: app.t('normal'), selected: _urgency == Urgency.normal, onTap: () => setState(() => _urgency = Urgency.normal))),
        const SizedBox(width: 8),
        Expanded(child: ChoiceTile(label: app.t('urgent'), selected: _urgency == Urgency.urgent, onTap: () => setState(() => _urgency = Urgency.urgent))),
      ]),
      const SizedBox(height: 14),
      FieldLabel(app.t('note'), optional: true),
      TextField(controller: _note, maxLines: 2, minLines: 1, decoration: InputDecoration(hintText: app.t('notePh'))),
      ErrorText(_error),
      const SizedBox(height: 16),
      PrimaryButton(label: app.t('post'), loading: _loading, onPressed: _submit),
    ]);
  }
}

/// A tappable field showing the picked value, or a hint until one is picked.
class _PickerBox extends StatelessWidget {
  const _PickerBox({required this.text, required this.hint, required this.icon, required this.onTap});
  final String? text;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            suffixIcon: Icon(icon, size: 18, color: AppColors.muted),
            suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Shrinks rather than cuts off a long date on narrow phones.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              text ?? hint,
              maxLines: 1,
              style: TextStyle(fontSize: 14, color: text == null ? AppColors.hint : AppColors.ink),
            ),
          ),
        ),
      );
}
