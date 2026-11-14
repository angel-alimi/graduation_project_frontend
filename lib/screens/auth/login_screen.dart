import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import 'otp_screen.dart';
import 'signup_info_screen.dart';

/// Login: phone number only, then the OTP. The user's details were saved at sign-up.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      await app.api.requestOtp(phone, OtpPurpose.login);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone, purpose: OtpPurpose.login)));
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
                const Row(children: [BackSquareButton(), Spacer(), LangToggle()]),
                const SizedBox(height: 32),
                Text(app.t('loginTitle'), style: tt.headlineSmall!.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(app.t('loginSub'), style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted)),
                const SizedBox(height: 28),
                AuthPhoneInput(
                  controller: _phone,
                  errorText: _error,
                  helperText: app.t('phoneStarts'),
                  onSubmitted: (_) => _send(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: PrimaryButton(label: app.t('continue'), height: 52, loading: _loading, onPressed: _send),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(app.t('noAccount'), style: TextStyle(fontSize: 13, color: AppColors.muted)),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (_) => const SignupInfoScreen())),
                child: Text(app.t('createAccount')),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
