import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../../widgets/mascot.dart';
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
    setState(() { _error = null; _loading = true; });
    try {
      await app.api.requestOtp(phone, OtpPurpose.login);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OtpScreen(phone: phone, purpose: OtpPurpose.login)));
    } catch (e) {
      if (mounted) setState(() => _error = app.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                const Row(children: [BackSquareButton(), Spacer(), LangToggle()]),
                const SizedBox(height: 20),
                Container(
                  height: 150,
                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.antiAlias,
                  child: const Mascot(pose: MascotPose.wave, size: 118),
                ),
                const SizedBox(height: 20),
                ScreenTitle(app.t('loginTitle'), subtitle: app.t('loginSub')),
                const SizedBox(height: 18),
                FieldLabel(app.t('phone')),
                PhoneField(controller: _phone, errorText: _error, onSubmitted: (_) => _send()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: PrimaryButton(label: app.t('sendCode'), loading: _loading, onPressed: _send),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(app.t('noAccount'), style: TextStyle(fontSize: 13, color: AppColors.muted)),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignupInfoScreen())),
                child: Text(app.t('createAccount')),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
