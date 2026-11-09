import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../core/search.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
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
  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;

  /// Optional extra contact numbers (the user's own number is always included).
  final List<TextEditingController> _extraPhones = [];
  final List<String?> _ePhones = [];
  static const _maxExtraPhones = 2;
  String? _error, _ePatient, _eHospital, _eNeeded;

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
    for (final c in _extraPhones) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.appRead;
    final neededAt = _neededAt;
    setState(() {
      _ePatient = _patient.text.trim().isEmpty ? app.t('ePatient') : null;
      _eHospital = _hospitalId == null ? app.t('eHospital') : null;
      _eNeeded = neededAt == null ? app.t('eNeededAt') : _pastError(app);
    });
    // Extra numbers: empty ones are ignored, others must be valid.
    for (var i = 0; i < _extraPhones.length; i++) {
      final v = _extraPhones[i].text.trim();
      _ePhones[i] = v.isEmpty || isValidPhone(v) ? null : app.t('ePhone');
    }
    setState(() {});
    if (_ePatient != null || _eHospital != null || _eNeeded != null || _ePhones.any((e) => e != null)) return;
    final confirmed = await _confirmRealRequest(context);
    if (confirmed != true || !mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      await app.api.createRequest(NewRequest(
        patientName: _patient.text,
        bloodType: _type,
        unitsNeeded: _units,
        hospitalId: _hospitalId!,
        urgency: Urgency.normal,
        neededAt: neededAt!,
        note: _note.text,
        contactPhones: {
          for (final c in _extraPhones)
            if (c.text.trim().isNotEmpty) normalizePhone(c.text),
        }.where((p) => p != normalizePhone(app.user?.phone ?? '')).toList(),
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
      FieldLabel(app.t('patientName')),
      TextField(
        controller: _patient,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(errorText: _ePatient),
        onChanged: (_) { if (_ePatient != null) setState(() => _ePatient = null); },
      ),
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
      FieldLabel(app.t('contactNumbers')),
      ListGroup(children: [
        ListRow(
          icon: Icons.phone_outlined,
          label: formatPhone(app.user?.phone ?? ''),
          value: app.t('yourNumber'),
        ),
      ]),
      for (var i = 0; i < _extraPhones.length; i++) ...[
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: PhoneField(controller: _extraPhones[i], errorText: _ePhones[i])),
          const SizedBox(width: 8),
          SquareIconButton(
            icon: Icons.close_rounded,
            size: 46,
            tooltip: app.t('removeNumber'),
            onPressed: () => setState(() {
              _extraPhones.removeAt(i).dispose();
              _ePhones.removeAt(i);
            }),
          ),
        ]),
      ],
      if (_extraPhones.length < _maxExtraPhones)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(horizontal: 4)),
            onPressed: () => setState(() {
              _extraPhones.add(TextEditingController());
              _ePhones.add(null);
            }),
            child: Text('+ ${app.t('addNumber')}  ·  ${app.t('optionalShort')}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      Text(app.t('contactNumbersSub'), style: TextStyle(fontSize: 12, color: AppColors.hint)),
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

/// Warning shown before posting: asks the user to confirm the request is genuine.
/// Returns true only when the user taps "Yes, post request".
Future<bool?> _confirmRealRequest(BuildContext context) {
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
          Text(app.t('confirmRealTitle'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(app.t('confirmRealBody'), style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.muted)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              textStyle: label.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text(app.t('confirmRealYes')),
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
            child: Text(app.t('confirmRealNo')),
          ),
        ]),
      ),
    ),
  );
}
