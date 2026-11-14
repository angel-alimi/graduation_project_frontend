import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

const _itemExtent = 40.0;
const _visibleItems = 5;

/// Centered pop-up with year, month and day wheels. Returns the picked day,
/// always inside [firstDate]..[lastDate], or null when closed.
Future<DateTime?> showWheelDatePicker(
  BuildContext context, {
  required String title,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => _DateWheelDialog(
      title: title,
      first: DateUtils.dateOnly(firstDate),
      last: DateUtils.dateOnly(lastDate),
      initial: DateUtils.dateOnly(initialDate ?? lastDate),
    ),
  );
}

/// Centered pop-up with hour, minute and AM/PM wheels. Minutes move in steps
/// of [minuteStep]. Returns null when closed.
Future<TimeOfDay?> showWheelTimePicker(
  BuildContext context, {
  required String title,
  required TimeOfDay initialTime,
  int minuteStep = 5,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (_) => _TimeWheelDialog(title: title, initial: initialTime, minuteStep: minuteStep),
  );
}

class _DateWheelDialog extends StatefulWidget {
  const _DateWheelDialog({required this.title, required this.first, required this.last, required this.initial});
  final String title;
  final DateTime first, last, initial;

  @override
  State<_DateWheelDialog> createState() => _DateWheelDialogState();
}

class _DateWheelDialogState extends State<_DateWheelDialog> {
  late int _year, _month, _day;
  late final FixedExtentScrollController _yearCtrl, _monthCtrl, _dayCtrl;

  DateTime get _first => widget.first;
  DateTime get _last => widget.last;

  DateTime _clamp(DateTime d) => d.isBefore(_first) ? _first : (d.isAfter(_last) ? _last : d);

  /// The date the wheels point at, pulled back into a real day and the allowed range.
  DateTime get _value {
    final days = DateUtils.getDaysInMonth(_year, _month);
    return _clamp(DateTime(_year, _month, _day > days ? days : _day));
  }

  bool _monthAllowed(int m) =>
      !DateTime(_year, m + 1, 0).isBefore(_first) && !DateTime(_year, m, 1).isAfter(_last);

  bool _dayAllowed(int d) {
    if (d > DateUtils.getDaysInMonth(_year, _month)) return false;
    final date = DateTime(_year, _month, d);
    return !date.isBefore(_first) && !date.isAfter(_last);
  }

  @override
  void initState() {
    super.initState();
    final v = _clamp(widget.initial);
    _year = v.year;
    _month = v.month;
    _day = v.day;
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _first.year);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  /// When the wheels stop on a date that does not exist or is out of range
  /// (e.g. 31 Feb), they roll back to the nearest allowed one.
  void _settle() {
    if (!mounted) return;
    final v = _value;
    _roll(_yearCtrl, v.year - _first.year);
    _roll(_monthCtrl, v.month - 1);
    _roll(_dayCtrl, v.day - 1);
  }

  void _roll(FixedExtentScrollController c, int item) {
    if (c.selectedItem != item) {
      c.animateToItem(item, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.app.lang;
    return _WheelDialog(
      title: widget.title,
      onScrollEnd: () => WidgetsBinding.instance.addPostFrameCallback((_) => _settle()),
      onSubmit: () => Navigator.of(context).pop(_value),
      wheels: [
        _Wheel(
          controller: _yearCtrl,
          count: _last.year - _first.year + 1,
          selected: _year - _first.year,
          label: (i) => '${_first.year + i}',
          onChanged: (i) => setState(() => _year = _first.year + i),
        ),
        _Wheel(
          controller: _monthCtrl,
          count: 12,
          selected: _month - 1,
          latin: lang != 'ar',
          label: (i) => monthName(i + 1, lang),
          enabled: (i) => _monthAllowed(i + 1),
          onChanged: (i) => setState(() => _month = i + 1),
        ),
        _Wheel(
          controller: _dayCtrl,
          count: 31,
          selected: _day - 1,
          label: (i) => '${i + 1}',
          enabled: (i) => _dayAllowed(i + 1),
          onChanged: (i) => setState(() => _day = i + 1),
        ),
      ],
    );
  }
}

class _TimeWheelDialog extends StatefulWidget {
  const _TimeWheelDialog({required this.title, required this.initial, required this.minuteStep});
  final String title;
  final TimeOfDay initial;
  final int minuteStep;

  @override
  State<_TimeWheelDialog> createState() => _TimeWheelDialogState();
}

class _TimeWheelDialogState extends State<_TimeWheelDialog> {
  /// Wheel positions: hour 0-11 (shown as 1-12), minute in steps, 0 = AM / 1 = PM.
  late int _hour, _minute, _period;
  late final FixedExtentScrollController _hourCtrl, _minuteCtrl, _periodCtrl;

  int get _minuteCount => 60 ~/ widget.minuteStep;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _hour = (t.hour + 11) % 12;
    _minute = (t.minute ~/ widget.minuteStep) % _minuteCount;
    _period = t.hour >= 12 ? 1 : 0;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _periodCtrl = FixedExtentScrollController(initialItem: _period);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _value =>
      TimeOfDay(hour: (_hour + 1) % 12 + _period * 12, minute: _minute * widget.minuteStep);

  @override
  Widget build(BuildContext context) {
    final lang = context.app.lang;
    return _WheelDialog(
      title: widget.title,
      onSubmit: () => Navigator.of(context).pop(_value),
      wheels: [
        _Wheel(
          controller: _hourCtrl,
          count: 12,
          looping: true,
          selected: _hour,
          label: (i) => '${i + 1}',
          onChanged: (i) => setState(() => _hour = i),
        ),
        _Wheel(
          controller: _minuteCtrl,
          count: _minuteCount,
          looping: true,
          selected: _minute,
          label: (i) => (i * widget.minuteStep).toString().padLeft(2, '0'),
          onChanged: (i) => setState(() => _minute = i),
        ),
        _Wheel(
          controller: _periodCtrl,
          count: 2,
          selected: _period,
          latin: lang != 'ar',
          label: (i) => dayPeriod(i == 1, lang),
          onChanged: (i) => setState(() => _period = i),
        ),
      ],
    );
  }
}

/// The pop-up card: title with a close button, the wheels with a highlighted
/// middle row, and a full-width confirm button.
class _WheelDialog extends StatelessWidget {
  const _WheelDialog({required this.title, required this.wheels, required this.onSubmit, this.onScrollEnd});
  final String title;
  final List<Widget> wheels;
  final VoidCallback onSubmit;
  final VoidCallback? onScrollEnd;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surface;
    final clear = surface.withValues(alpha: 0);
    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 54,
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              PositionedDirectional(
                end: 4,
                child: IconButton(
                  tooltip: context.tr('close'),
                  icon: Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ]),
          ),
          Divider(height: 1, color: AppColors.line),
          SizedBox(
            height: _itemExtent * _visibleItems,
            child: Stack(children: [
              // Highlighted middle row.
              Center(
                child: Container(
                  height: _itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              // Same wheel order in both languages.
              Directionality(
                textDirection: TextDirection.ltr,
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (_) {
                    onScrollEnd?.call();
                    return false;
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: wheels),
                  ),
                ),
              ),
              // Rows fade out towards the top and bottom edges.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [surface, clear, clear, surface],
                        stops: const [0, .36, .64, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: PrimaryButton(label: context.tr('confirm'), height: 50, onPressed: onSubmit),
          ),
        ]),
      ),
    );
  }
}

/// One scrolling column. Rows that cannot be picked are shown faded.
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.enabled,
    this.looping = false,
    this.latin = true,
  });
  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;
  final bool Function(int index)? enabled;

  /// Goes round and round (hours, minutes) instead of stopping at the ends.
  final bool looping;

  /// Numbers and English text use the Latin font; Arabic words use the app font.
  final bool latin;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        diameterRatio: 1.7,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) => onChanged(i % count),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: looping ? null : count,
          builder: (context, raw) {
            final i = raw % count;
            final on = i == selected;
            final allowed = enabled?.call(i) ?? true;
            final color = on ? AppColors.ink : AppColors.muted;
            return Center(
              child: Text(
                label(i),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: latin ? AppFonts.latin : null,
                  fontSize: on ? 17 : 15,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  color: allowed ? color : color.withValues(alpha: .3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
