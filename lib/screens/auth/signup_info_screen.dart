import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/search_picker.dart';
import '../../widgets/wheel_picker.dart';
import '../terms_screen.dart';
import 'signup_phone_screen.dart';

/// Sign-up step 1: name, birth date, city, gender, blood type, last donation.
class SignupInfoScreen extends StatefulWidget {
  const SignupInfoScreen({super.key});

  @override
  State<SignupInfoScreen> createState() => _SignupInfoScreenState();
}

class _SignupInfoScreenState extends State<SignupInfoScreen> {
  final _data = SignupData();
  final _first = TextEditingController();
  final _last = TextEditingController();
  String? _eFirst, _eLast, _eDob, _eCity, _eGender;
  bool _agreeTerms = false, _agreeData = false;
  bool get _agreed => _agreeTerms && _agreeData;

  @override
  void initState() {
    super.initState();
    context.appRead.ensureLookups().catchError((_) {});
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showWheelDatePicker(
      context,
      title: context.appRead.t('birthDate'),
      initialDate:
          _data.birthDate ?? DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(now.year - 70),
      lastDate: now,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _data.birthDate = picked;
        _eDob = null;
        final last = _data.lastDonationDate;
        if (last != null && last.isBefore(picked)) {
          _data.lastDonationDate = null;
        }
      });
    }
  }

  Future<void> _pickLastDonation() async {
    final now = DateTime.now();
    final picked = await showWheelDatePicker(
      context,
      title: context.appRead.t('lastDonationDate'),
      initialDate: _data.lastDonationDate ?? now,
      firstDate: _data.birthDate ?? DateTime(now.year - 70),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _data.lastDonationDate = picked);
    }
  }

  void _submit() {
    final app = context.appRead;
    setState(() {
      final first = _first.text.trim(), last = _last.text.trim();
      _data.fullName = '$first $last';
      _eFirst = first.length < 2 ? app.t('eFirstName') : null;
      _eLast = last.length < 2 ? app.t('eLastName') : null;
      if (_data.birthDate == null) {
        _eDob = app.t('eDob');
      } else {
        final age = DateTime.now().difference(_data.birthDate!).inDays / 365.25;
        _eDob = age < AppConfig.minimumAge ? app.t('eAge') : null;
      }
      _eCity = _data.cityId == null ? app.t('eCity') : null;
      _eGender = _data.gender == null ? app.t('eGender') : null;
    });
    if ([_eFirst, _eLast, _eDob, _eCity, _eGender].every((e) => e == null) &&
        _agreed) {
      _data
        ..termsVersion = kTermsVersion
        ..termsAcceptedAt = DateTime.now();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SignupPhoneScreen(data: _data)));
    }
  }

  /// A tappable field that opens a date picker (looks like the text fields).
  Widget _dateField(
      {required DateTime? value,
      required VoidCallback onTap,
      String? error,
      String? helper,
      VoidCallback? onClear}) {
    final app = context.app;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          errorText: error,
          errorMaxLines: 2,
          helperText: helper,
          helperMaxLines: 2,
          suffixIcon: value != null && onClear != null
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.muted),
                  tooltip: app.t('clear'),
                  onPressed: onClear,
                )
              : Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.muted),
        ),
        child: Text(
          value == null ? app.t('pickDate') : formatDate(value, app.lang),
          style: TextStyle(
            fontSize: 14,
            color: value == null ? AppColors.hint : AppColors.ink,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final tt = Theme.of(context).textTheme;
    const gap = SizedBox(height: 18);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const StepHeader(step: 1),
                const SizedBox(height: 32),
                Text(app.t('infoTitle'),
                    style: tt.headlineSmall!.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(app.t('infoSub'),
                    style: TextStyle(
                        fontSize: 15, height: 1.5, color: AppColors.muted)),
                const SizedBox(height: 28),
                FieldLabel(app.t('firstName')),
                TextField(
                  controller: _first,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  decoration: InputDecoration(
                      hintText: app.t('firstNamePh'), errorText: _eFirst),
                  onChanged: (_) {
                    if (_eFirst != null) setState(() => _eFirst = null);
                  },
                ),
                gap,
                FieldLabel(app.t('lastName')),
                TextField(
                  controller: _last,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  decoration: InputDecoration(
                      hintText: app.t('lastNamePh'), errorText: _eLast),
                  onChanged: (_) {
                    if (_eLast != null) setState(() => _eLast = null);
                  },
                ),
                gap,
                FieldLabel(app.t('birthDate')),
                _dateField(
                    value: _data.birthDate, onTap: _pickDate, error: _eDob),
                gap,
                FieldLabel(app.t('gender')),
                Row(children: [
                  Expanded(
                    child: ChoiceTile(
                      label: app.t('female'),
                      height: 46,
                      selected: _data.gender == Gender.female,
                      onTap: () => setState(() {
                        _data.gender = Gender.female;
                        _eGender = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceTile(
                      label: app.t('male'),
                      height: 46,
                      selected: _data.gender == Gender.male,
                      onTap: () => setState(() {
                        _data.gender = Gender.male;
                        _eGender = null;
                      }),
                    ),
                  ),
                ]),
                ErrorText(_eGender),
                gap,
                FieldLabel(app.t('city')),
                SearchPickerField<int>(
                  value: _data.cityId,
                  hint: app.t('pickCity'),
                  searchHint: app.t('searchCity'),
                  errorText: _eCity,
                  options: sortedOptions([
                    for (final c in app.cities)
                      PickerOption(
                          value: c.id,
                          label: c.name(app.lang),
                          searchText: '${c.nameAr} ${c.nameEn}'),
                  ]),
                  onChanged: (v) => setState(() {
                    _data.cityId = v;
                    _eCity = null;
                  }),
                ),
                gap,
                FieldLabel(app.t('bloodType')),
                BloodTypeGrid(
                    value: _data.bloodType,
                    onChanged: (b) => setState(() => _data.bloodType = b)),
                gap,
                FieldLabel(app.t('lastDonationDate'), optional: true),
                _dateField(
                  value: _data.lastDonationDate,
                  onTap: _pickLastDonation,
                  helper: app.t('lastDonationHelp'),
                  onClear: () => setState(() => _data.lastDonationDate = null),
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 8),
                TermsAgreeTile(
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v)),
                TermsAgreeTile(
                  value: _agreeData,
                  text: app.t('agreeData'),
                  onChanged: (v) => setState(() => _agreeData = v),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line))),
            child: PrimaryButton(
                label: app.t('continue'),
                height: 52,
                onPressed: _agreed ? _submit : null),
          ),
        ]),
      ),
    );
  }
}
