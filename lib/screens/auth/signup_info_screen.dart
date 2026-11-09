import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/search_picker.dart';
import 'signup_phone_screen.dart';

/// Sign-up step 1: name, birth date, city, gender, blood type, last donation.
class SignupInfoScreen extends StatefulWidget {
  const SignupInfoScreen({super.key});

  @override
  State<SignupInfoScreen> createState() => _SignupInfoScreenState();
}

class _SignupInfoScreenState extends State<SignupInfoScreen> {
  final _data = SignupData();
  final _name = TextEditingController();
  String? _eName, _eDob, _eCity, _eGender;

  @override
  void initState() {
    super.initState();
    context.appRead.ensureLookups().catchError((_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.birthDate ?? DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(now.year - 70),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _data.birthDate = picked;
        _eDob = null;
        final last = _data.lastDonationDate;
        if (last != null && last.isBefore(picked)) _data.lastDonationDate = null;
      });
    }
  }

  Future<void> _pickLastDonation() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.lastDonationDate ?? now,
      firstDate: _data.birthDate ?? DateTime(now.year - 70),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _data.lastDonationDate = picked);
  }

  void _submit() {
    final app = context.appRead;
    setState(() {
      _data.fullName = _name.text.trim();
      _eName = _data.fullName.length < 3 ? app.t('eName') : null;
      if (_data.birthDate == null) {
        _eDob = app.t('eDob');
      } else {
        final age = DateTime.now().difference(_data.birthDate!).inDays / 365.25;
        _eDob = age < AppConfig.minimumAge ? app.t('eAge') : null;
      }
      _eCity = _data.cityId == null ? app.t('eCity') : null;
      _eGender = _data.gender == null ? app.t('eGender') : null;
    });
    if ([_eName, _eDob, _eCity, _eGender].every((e) => e == null)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupPhoneScreen(data: _data)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final dob = _data.birthDate;
    final lastDonation = _data.lastDonationDate;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const StepHeader(step: 1),
                const SizedBox(height: 20),
                ScreenTitle(app.t('infoTitle'), subtitle: app.t('infoSub')),
                const SizedBox(height: 20),
                FieldLabel(app.t('fullName')),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(hintText: app.t('namePh'), errorText: _eName),
                  onChanged: (_) { if (_eName != null) setState(() => _eName = null); },
                ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FieldLabel(app.t('birthDate')),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            errorText: _eDob,
                            errorMaxLines: 2,
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
                          ),
                          child: Text(
                            dob == null ? app.t('pickDate') : formatYmd(dob),
                            style: TextStyle(
                              fontSize: 14,
                              color: dob == null ? AppColors.hint : AppColors.ink,
                              fontFamily: dob == null ? null : AppFonts.latin,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FieldLabel(app.t('city')),
                      SearchPickerField<int>(
                        value: _data.cityId,
                        hint: app.t('pickCity'),
                        searchHint: app.t('searchCity'),
                        errorText: _eCity,
                        options: sortedOptions([
                          for (final c in app.cities)
                            PickerOption(value: c.id, label: c.name(app.lang), searchText: '${c.nameAr} ${c.nameEn}'),
                        ]),
                        onChanged: (v) => setState(() { _data.cityId = v; _eCity = null; }),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                FieldLabel(app.t('gender')),
                Row(children: [
                  Expanded(
                    child: ChoiceTile(
                      label: app.t('female'),
                      selected: _data.gender == Gender.female,
                      onTap: () => setState(() { _data.gender = Gender.female; _eGender = null; }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceTile(
                      label: app.t('male'),
                      selected: _data.gender == Gender.male,
                      onTap: () => setState(() { _data.gender = Gender.male; _eGender = null; }),
                    ),
                  ),
                ]),
                ErrorText(_eGender),
                const SizedBox(height: 16),
                FieldLabel(app.t('bloodType')),
                BloodTypeGrid(value: _data.bloodType, onChanged: (b) => setState(() => _data.bloodType = b)),
                const SizedBox(height: 16),
                FieldLabel(app.t('lastDonationDate'), optional: true),
                InkWell(
                  onTap: _pickLastDonation,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      helperText: app.t('lastDonationHelp'),
                      helperMaxLines: 2,
                      suffixIcon: lastDonation == null
                          ? const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted)
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                              tooltip: app.t('clear'),
                              onPressed: () => setState(() => _data.lastDonationDate = null),
                            ),
                    ),
                    child: Text(
                      lastDonation == null ? app.t('pickDate') : formatYmd(lastDonation),
                      style: TextStyle(
                        fontSize: 14,
                        color: lastDonation == null ? AppColors.hint : AppColors.ink,
                        fontFamily: lastDonation == null ? null : AppFonts.latin,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: PrimaryButton(label: app.t('next'), onPressed: _submit),
          ),
        ]),
      ),
    );
  }
}
