import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../../widgets/mascot.dart';
import '../../widgets/scene_art.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const AuthHero(pose: MascotPose.phone, step: 2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenTitle(app.t('phoneTitle'),
                              subtitle: app.t('phoneSub')),
                          const SizedBox(height: 18),
                          FieldLabel(app.t('phone')),
                          PhoneField(
                              controller: _phone,
                              errorText: _error,
                              onSubmitted: (_) => _send()),
                          const SizedBox(height: 12),
                          Row(children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 14, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(app.t('private'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                          ]),
                        ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton(
                  label: app.t('sendCode'),
                  loading: _loading,
                  onPressed: _send),
            ),
          ]),
        ),
      ),
    );
  }
}
