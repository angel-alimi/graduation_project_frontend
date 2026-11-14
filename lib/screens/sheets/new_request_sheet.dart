import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../core/search.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../../widgets/search_picker.dart';
import '../../widgets/wheel_picker.dart';

/// Opens the "New blood request" form as a full page. Returns true when a request was posted.
Future<bool?> showNewRequestSheet(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
        fullscreenDialog: true, builder: (_) => const _NewRequestForm()),
  );
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

  /// Main contact number: the user's own number by default, can be changed, required.
  late final _mainPhone = TextEditingController(
      text: _formatted(context.appRead.user?.phone ?? ''));
  String? _eMainPhone;

  /// Optional extra contact numbers.
  final List<TextEditingController> _extraPhones = [];
  final List<String?> _ePhones = [];
  static const _maxExtraPhones = 2;
  static const _maxUnits = 10;
  String? _error, _ePatient, _eHospital, _eNeeded;

  /// How far ahead a request can be scheduled.
  static const _maxDaysAhead = 90;

  DateTime? get _neededAt {
    final d = _date, t = _time;
    return d == null || t == null
        ? null
        : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  /// An error when the chosen moment has passed. Nothing while a part is still missing.
  String? _pastError(AppState app) {
    final at = _neededAt;
    return at != null && !at.isAfter(DateTime.now())
        ? app.t('eNeededPast')
        : null;
  }

  Future<void> _pickDate() async {
    final app = context.appRead;
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showWheelDatePicker(
      context,
      title: app.t('pickDate'),
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: _maxDaysAhead)),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _eNeeded = _pastError(app);
      });
    }
  }

  Future<void> _pickTime() async {
    final app = context.appRead;
    final picked = await showWheelTimePicker(
      context,
      title: app.t('pickTime'),
      initialTime: _time ??
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );
    if (picked != null && mounted) {
      setState(() {
        _time = picked;
        _eNeeded = _pastError(app);
      });
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

  static String _formatted(String phone) => const PhoneInputFormatter()
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: phone))
      .text;

  @override
  void dispose() {
    _mainPhone.dispose();
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
      _eMainPhone = isValidPhone(_mainPhone.text) ? null : app.t('ePhone');
    });
    // Extra numbers: empty ones are ignored, others must be valid.
    for (var i = 0; i < _extraPhones.length; i++) {
      final v = _extraPhones[i].text.trim();
      _ePhones[i] = v.isEmpty || isValidPhone(v) ? null : app.t('ePhone');
    }
    setState(() {});
    if (_ePatient != null ||
        _eHospital != null ||
        _eNeeded != null ||
        _eMainPhone != null ||
        _ePhones.any((e) => e != null)) {
      return;
    }
    final confirmed = await _confirmRealRequest(context);
    if (confirmed != true || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await app.api.createRequest(NewRequest(
        patientName: _patient.text,
        bloodType: _type,
        unitsNeeded: _units,
        hospitalId: _hospitalId!,
        neededAt: neededAt!,
        note: _note.text,
        contactPhone: normalizePhone(_mainPhone.text),
        contactPhones: {
          for (final c in _extraPhones)
            if (c.text.trim().isNotEmpty) normalizePhone(c.text),
        }.where((p) => p != normalizePhone(_mainPhone.text)).toList(),
      ));
      if (!mounted) return;
      app.refreshUser().catchError((_) {});
      Navigator.of(context).pop(true);
      context.toast(app.t('posted'));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = app.errorText(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    const gap = SizedBox(height: 18);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: .5,
        shadowColor: AppColors.line,
        centerTitle: true,
        leading: IconButton(
          tooltip: app.t('close'),
          icon: Icon(Icons.close_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(app.t('newRequestTitle'),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: app.t('secPatient'),
            children: [
              FieldLabel(app.t('patientName')),
              TextField(
                controller: _patient,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                    hintText: app.t('patientNamePh'), errorText: _ePatient),
                onChanged: (_) {
                  if (_ePatient != null) setState(() => _ePatient = null);
                },
              ),
              gap,
              FieldLabel(app.t('neededType')),
              BloodTypeGrid(
                  value: _type, onChanged: (b) => setState(() => _type = b)),
              gap,
              Row(children: [
                Expanded(
                  child: Text(app.t('unitsNeeded'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ),
                _UnitsStepper(
                    value: _units,
                    max: _maxUnits,
                    onChanged: (v) => setState(() => _units = v)),
              ]),
            ],
          ),
          _SectionCard(
            icon: Icons.local_hospital_outlined,
            title: app.t('secWhere'),
            children: [
              FieldLabel(app.t('hospital')),
              SearchPickerField<int>(
                value: _hospitalId,
                hint: app.t('pickHospital'),
                searchHint: app.t('searchHospital'),
                errorText: _eHospital,
                options: _hospitalOptions(app),
                onChanged: (v) => setState(() {
                  _hospitalId = v;
                  _eHospital = null;
                }),
              ),
              gap,
              FieldLabel(app.t('neededAt')),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: _PickerBox(
                    text: _date == null ? null : formatDate(_date!, app.lang),
                    hint: app.t('pickDate'),
                    icon: Icons.calendar_today_outlined,
                    hasError: _eNeeded != null,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _PickerBox(
                    text: _time == null
                        ? null
                        : formatTime(_time!.hour, _time!.minute, app.lang),
                    hint: app.t('pickTime'),
                    icon: Icons.access_time_rounded,
                    hasError: _eNeeded != null,
                    onTap: _pickTime,
                  ),
                ),
              ]),
              ErrorText(_eNeeded),
            ],
          ),
          _SectionCard(
            icon: Icons.phone_outlined,
            title: app.t('contactNumbers'),
            subtitle: app.t('contactNumbersSub'),
            children: [
              FieldLabel(app.t('mainNumber')),
              PhoneField(
                controller: _mainPhone,
                errorText: _eMainPhone,
                helperText: app.t('phoneStarts'),
                onChanged: (_) {
                  if (_eMainPhone != null) setState(() => _eMainPhone = null);
                },
              ),
              for (var i = 0; i < _extraPhones.length; i++) ...[
                const SizedBox(height: 14),
                FieldLabel(app.t('extraNumber'), optional: true),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: PhoneField(
                          controller: _extraPhones[i], errorText: _ePhones[i])),
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
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(horizontal: 4)),
                      onPressed: () => setState(() {
                        _extraPhones.add(TextEditingController());
                        _ePhones.add(null);
                      }),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(app.t('addNumber'),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ],
          ),
          _SectionCard(
            icon: Icons.notes_rounded,
            title: app.t('secMore'),
            children: [
              FieldLabel(app.t('note'), optional: true),
              TextField(
                  controller: _note,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(hintText: app.t('notePh'))),
            ],
          ),
          ErrorText(_error),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line))),
          child: PrimaryButton(
              label: app.t('post'),
              height: 52,
              loading: _loading,
              onPressed: _submit),
        ),
      ),
    );
  }
}

/// One card of the form: an icon and a title, then the fields.
class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon,
      required this.title,
      required this.children,
      this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                IconBox(icon, size: 34, bg: AppColors.chip, fg: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ]),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(subtitle!,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: AppColors.muted)),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );
}

/// Minus button, the number, plus button. Stays within 1..[max].
class _UnitsStepper extends StatelessWidget {
  const _UnitsStepper(
      {required this.value, required this.max, required this.onChanged});
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SquareIconButton(
              icon: Icons.remove_rounded,
              size: 40,
              filled: true,
              onPressed: value > 1 ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 44,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: AppFonts.latin,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
          SquareIconButton(
              icon: Icons.add_rounded,
              size: 40,
              filled: true,
              onPressed: value < max ? () => onChanged(value + 1) : null),
        ],
      );
}

/// A tappable field showing the picked value, or a hint until one is picked.
class _PickerBox extends StatelessWidget {
  const _PickerBox(
      {required this.text,
      required this.hint,
      required this.icon,
      required this.onTap,
      this.hasError = false});
  final String? text;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            enabledBorder: hasError
                ? Theme.of(context).inputDecorationTheme.errorBorder
                : null,
            suffixIcon: Icon(icon, size: 18, color: AppColors.muted),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Shrinks rather than cuts off a long date on narrow phones.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              text ?? hint,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 14,
                  color: text == null ? AppColors.hint : AppColors.ink),
            ),
          ),
        ),
      );
}

/// Warning shown before posting: asks the user to confirm the request is genuine.
/// Returns true only when the user taps "Yes, post request".
Future<bool?> _confirmRealRequest(BuildContext context) {
  final app = context.appRead;
  return showConfirmDialog(
    context,
    title: app.t('confirmRealTitle'),
    message: app.t('confirmRealBody'),
    confirmLabel: app.t('confirmRealYes'),
    cancelLabel: app.t('confirmRealNo'),
  );
}
