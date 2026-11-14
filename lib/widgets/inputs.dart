import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

/// Normalises what the user typed into 9 local digits (e.g. 0591234567 -> 591234567).
String normalizePhone(String v) {
  var x = v.replaceAll(RegExp(r'\D'), '');
  if (x.startsWith('970')) x = x.substring(3);
  if (x.startsWith('0')) x = x.substring(1);
  return x;
}

/// Palestinian mobile numbers: 59x or 56x, 9 digits.
bool isValidPhone(String v) => RegExp(r'^5[69]\d{7}$').hasMatch(normalizePhone(v));

String formatPhone(String local) {
  final d = normalizePhone(local);
  if (d.length < 5) return '+970 $d';
  final a = d.substring(0, 2), b = d.substring(2, 5), c = d.substring(5);
  return '+970 $a $b $c'.trim();
}

/// Phone number formatter: keeps digits only, drops a leading 0 or 970 (when
/// pasted), stops at the 9 digits of a local mobile number and shows it as
/// "5XX XXX XXX". Extra typing is ignored.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();
  static const maxDigits = 9;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > maxDigits && d.startsWith('970')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    if (d.length > maxDigits) d = d.substring(0, maxDigits);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(d[i]);
    }
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// +970 prefix and a number field, always left-to-right.
class PhoneField extends StatelessWidget {
  const PhoneField(
      {super.key, required this.controller, this.errorText, this.helperText, this.onSubmitted, this.onChanged, this.autofocus = false});
  final TextEditingController controller;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: const [PhoneInputFormatter()],
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 15, letterSpacing: .5),
        decoration: InputDecoration(
          hintText: '5XX XXX XXX',
          errorText: errorText,
          helperText: helperText,
          prefixIcon: Container(
            width: 64,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.line))),
            alignment: Alignment.center,
            child: Text('+970', style: TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 64, minHeight: 46),
        ),
      ),
    );
  }
}

/// Six boxes backed by one hidden text field, so paste, autofill and backspace all work.
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.controller, required this.onCompleted, this.length = 6, this.hasError = false});
  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool hasError;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _changed() {
    setState(() {});
    if (widget.controller.text.length == widget.length) widget.onCompleted(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(children: [
          // Invisible field that receives the keyboard input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(border: InputBorder.none, filled: false),
              ),
            ),
          ),
          IgnorePointer(
            child: Row(children: [
              for (var i = 0; i < widget.length; i++) ...[
                Expanded(child: _box(i, text)),
                if (i < widget.length - 1) const SizedBox(width: 8),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _box(int i, String text) {
    final filled = i < text.length;
    final active = _focus.hasFocus && (i == text.length || (i == widget.length - 1 && text.length == widget.length));
    final color = widget.hasError ? AppColors.errorBorder : (active ? AppColors.redText : AppColors.field);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: active ? 1.5 : 1),
        boxShadow: active ? [BoxShadow(color: AppColors.redText.withValues(alpha: .12), blurRadius: 0, spreadRadius: 3)] : null,
      ),
      child: Text(filled ? text[i] : '',
          style: TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.ink)),
    );
  }
}

const _psFlag = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 6 4">'
    '<rect width="6" height="4" fill="#007A3D"/><rect width="6" height="2.667" fill="#FFFFFF"/>'
    '<rect width="6" height="1.333" fill="#000000"/><path d="M0 0L3 2L0 4Z" fill="#CE1126"/></svg>';

/// Large phone input for the login and sign-up screens: a country box
/// (flag + code) and the number, inside one field. Always left-to-right.
class AuthPhoneInput extends StatefulWidget {
  const AuthPhoneInput({super.key, required this.controller, this.errorText, this.helperText, this.onSubmitted});
  final TextEditingController controller;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthPhoneInput> createState() => _AuthPhoneInputState();
}

class _AuthPhoneInputState extends State<AuthPhoneInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText != null;
    final borderColor = error ? AppColors.errorBorder : (_focus.hasFocus ? AppColors.redText : AppColors.field);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focus.hasFocus || error ? 1.5 : 1),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SvgPicture.string(_psFlag, width: 24, height: 16),
            ),
            const SizedBox(width: 8),
            Text('+970',
                style: TextStyle(fontFamily: AppFonts.latin, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(width: 12),
            Container(width: 1, height: 26, color: AppColors.line),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: const [PhoneInputFormatter()],
                onSubmitted: widget.onSubmitted,
                style: TextStyle(fontFamily: AppFonts.latin, fontSize: 17, letterSpacing: 1, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: '5XX XXX XXX',
                  hintStyle: TextStyle(fontFamily: AppFonts.latin, fontSize: 17, letterSpacing: 1, color: AppColors.hint),
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                ),
              ),
            ),
          ]),
        ),
      ),
      if (error)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
          child: Text(widget.errorText!, style: TextStyle(fontSize: 12.5, color: AppColors.error)),
        )
      else if (widget.helperText != null)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
          child: Text(widget.helperText!, style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
        ),
    ]);
  }
}
