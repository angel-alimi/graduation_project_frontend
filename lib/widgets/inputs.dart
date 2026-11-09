import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// +970 prefix and a number field, always left-to-right.
class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller, this.errorText, this.onSubmitted, this.autofocus = false});
  final TextEditingController controller;
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
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(12)],
        onSubmitted: onSubmitted,
        style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 15, letterSpacing: .5),
        decoration: InputDecoration(
          hintText: '59X XXX XXX',
          errorText: errorText,
          prefixIcon: Container(
            width: 64,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.line))),
            alignment: Alignment.center,
            child: const Text('+970', style: TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
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
    final color = widget.hasError ? const Color(0xFFC2410C) : (active ? AppColors.red : AppColors.field);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: active ? 1.5 : 1),
        boxShadow: active ? const [BoxShadow(color: Color(0x1AA71930), blurRadius: 0, spreadRadius: 3)] : null,
      ),
      child: Text(filled ? text[i] : '',
          style: const TextStyle(fontFamily: AppFonts.latin, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.ink)),
    );
  }
}
