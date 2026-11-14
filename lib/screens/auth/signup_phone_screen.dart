import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import 'otp_screen.dart';

/// Sign-up step 2: phone number. Sends the OTP and opens step 3.
class SignupPhoneScreen extends StatefulWidget {
  const SignupPhoneScreen({super.key, required this.data});
  final SignupData data;

  @override
  State<SignupPhoneScreen> createState() => _SignupPhoneScreenState();
}

class _SignupPhoneScreenState extends State<SignupPhoneScreen> {
  final _phone = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = context.appRead;
    if (!isValidPhone(_phone.text)) {
      setState(() => _error = app.t('ePhone'));
      return;
    }
    final phone = normalizePhone(_phone.text);
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await app.api.requestOtp(phone, OtpPurpose.signup);
      widget.data.phone = phone;
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(
            phone: phone, purpose: OtpPurpose.signup, signupData: widget.data),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = app.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const StepHeader(step: 2),
                const SizedBox(height: 32),
                Text(app.t('phoneTitle'), style: tt.headlineSmall!.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(app.t('phoneSub'), style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted)),
                const SizedBox(height: 28),
                AuthPhoneInput(
                  controller: _phone,
                  errorText: _error,
                  helperText: app.t('phoneStarts'),
                  onSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.hint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(app.t('private'), style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.hint))),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: PrimaryButton(label: app.t('continue'), height: 52, loading: _loading, onPressed: _send),
          ),
        ]),
      ),
    );
  }
}
