import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/inputs.dart';
import '../home_shell.dart';

/// Shared OTP step for sign-up (step 3) and login.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.purpose, this.signupData});
  final String phone;
  final OtpPurpose purpose;
  final SignupData? signupData;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _left = AppConfig.otpResendSeconds;
  bool _loading = false;
  String? _error;

  bool get _isSignup => widget.purpose == OtpPurpose.signup;

  @override
  void initState() {
    super.initState();
    _startTimer(first: true);
  }

  void _startTimer({bool first = false}) {
    _timer?.cancel();
    if (first) {
      _left = AppConfig.otpResendSeconds;
    } else {
      setState(() => _left = AppConfig.otpResendSeconds);
    }
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      if (mounted) setState(() => _left--);
    });
  }

  Future<void> _resend() async {
    final app = context.appRead;
    try {
      await app.api.requestOtp(widget.phone, widget.purpose);
      if (!mounted) return;
      context.toast(app.t('codeSent'));
      _startTimer();
    } catch (e) {
      if (mounted) context.toast(app.errorText(e));
    }
  }

  Future<void> _verify([String? _]) async {
    if (_loading || _code.text.length != 6) return;
    final app = context.appRead;
    setState(() { _loading = true; _error = null; });
    try {
      final result = _isSignup
          ? await app.api.signup(widget.signupData!, _code.text)
          : await app.api.login(widget.phone, _code.text);
      await app.setSession(result);
      if (!mounted) return;
      await _showWelcome(result.user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = app.errorText(e); _loading = false; });
      _code.clear();
    }
  }

  Future<void> _showWelcome(AppUser user) async {
    final app = context.appRead;
    final title = _isSignup
        ? app.t(user.gender == Gender.female ? 'welcomeF' : 'welcomeM', {'name': user.fullName})
        : app.t('welcomeBack');
    final sub = _isSignup ? app.t('welcomeSub') : app.t('welcomeBackSub');
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.surface,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Material(
        color: AppColors.surface,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .7, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.redText.withValues(alpha: .12), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 34, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.muted)),
          ]),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                StepHeader(step: 3, showSteps: _isSignup),
                const SizedBox(height: 24),
                Align(alignment: AlignmentDirectional.centerStart, child: IconBox(Icons.sms_outlined, size: 52)),
                const SizedBox(height: 18),
                Text(app.t('otpTitle'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('${app.t('otpSub')} ', style: TextStyle(color: AppColors.muted)),
                  Text(formatPhone(widget.phone),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800)),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(app.t('edit'))),
                ]),
                const SizedBox(height: 16),
                OtpInput(controller: _code, onCompleted: _verify, hasError: _error != null),
                ErrorText(_error),
                if (AppConfig.useMock) ...[
                  const SizedBox(height: 12),
                  Text(app.t('otpDemo'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(app.t('noCode'), style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(width: 6),
                  if (_left > 0)
                    Text(app.t('resendIn', {'s': '$mm:$ss'}), style: TextStyle(fontSize: 13, color: AppColors.muted))
                  else
                    TextButton(onPressed: _resend, child: Text(app.t('resend'))),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _code,
              builder: (_, v, __) => PrimaryButton(
                label: app.t(_isSignup ? 'createAccount' : 'confirm'),
                loading: _loading,
                onPressed: v.text.length == 6 ? _verify : null,
              ),
            ),
          ),
        ]),
      ),
    );
  }

}
