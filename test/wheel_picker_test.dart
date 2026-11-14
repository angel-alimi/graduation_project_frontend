import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeshare/core/theme.dart';
import 'package:lifeshare/state/app_state.dart';
import 'package:lifeshare/widgets/wheel_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    state = await AppState.create();
  });

  /// Shows a page with one button that opens [open] and keeps its result.
  Future<List<Object?>> pumpOpener(
      WidgetTester tester, Future<Object?> Function(BuildContext) open, {bool dark = false}) async {
    final result = <Object?>[];
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
        theme: buildTheme('en', dark: dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () async => result.add(await open(context)), child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Finder wheel(int index) => find.byType(ListWheelScrollView).at(index);

  group('Wheel date picker', () {
    for (final dark in [false, true]) {
      testWidgets('confirm returns the date shown (dark: $dark)', (tester) async {
        final result = await pumpOpener(
          tester,
          dark: dark,
          (c) => showWheelDatePicker(c,
              title: 'Date of birth',
              initialDate: DateTime(1998, 6, 24),
              firstDate: DateTime(1950),
              lastDate: DateTime(2026, 11, 14)),
        );
        expect(find.text('Date of birth'), findsOneWidget);
        expect(find.text('1998'), findsOneWidget);
        expect(find.text('Jun'), findsOneWidget);
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(result, [DateTime(1998, 6, 24)]);
      });
    }

    testWidgets('scrolling a wheel changes the date', (tester) async {
      final result = await pumpOpener(
        tester,
        (c) => showWheelDatePicker(c,
            title: 't', initialDate: DateTime(1998, 6, 24), firstDate: DateTime(1950), lastDate: DateTime(2026, 11, 14)),
      );
      await tester.drag(wheel(0), const Offset(0, -80)); // two years on
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, [DateTime(2000, 6, 24)]);
    });

    testWidgets('a day that does not exist rolls back to the last real one', (tester) async {
      final result = await pumpOpener(
        tester,
        (c) => showWheelDatePicker(c,
            title: 't', initialDate: DateTime(1999, 3, 31), firstDate: DateTime(1950), lastDate: DateTime(2026, 11, 14)),
      );
      await tester.drag(wheel(1), const Offset(0, 40)); // March -> February
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, [DateTime(1999, 2, 28)]);
    });

    testWidgets('cannot leave the allowed range', (tester) async {
      final result = await pumpOpener(
        tester,
        (c) => showWheelDatePicker(c,
            title: 't', initialDate: DateTime(2026, 11, 14), firstDate: DateTime(2026, 11, 14), lastDate: DateTime(2027, 2, 12)),
      );
      await tester.drag(wheel(2), const Offset(0, 200)); // towards day 9
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, [DateTime(2026, 11, 14)]);
    });

    testWidgets('close returns nothing', (tester) async {
      final result = await pumpOpener(
        tester,
        (c) => showWheelDatePicker(c, title: 't', firstDate: DateTime(1950), lastDate: DateTime(2026, 11, 14)),
      );
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(result, [null]);
    });
  });

  group('Wheel time picker', () {
    testWidgets('keeps the time and converts 12-hour to 24-hour', (tester) async {
      for (final t in const [
        TimeOfDay(hour: 0, minute: 0),
        TimeOfDay(hour: 12, minute: 30),
        TimeOfDay(hour: 14, minute: 5),
        TimeOfDay(hour: 23, minute: 55),
      ]) {
        final result = await pumpOpener(tester, (c) => showWheelTimePicker(c, title: 't', initialTime: t));
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(result, [t]);
      }
    });

    testWidgets('AM/PM wheel switches the half of the day', (tester) async {
      final result = await pumpOpener(
          tester, (c) => showWheelTimePicker(c, title: 't', initialTime: const TimeOfDay(hour: 9, minute: 15)));
      await tester.drag(wheel(2), const Offset(0, -40));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, [const TimeOfDay(hour: 21, minute: 15)]);
    });
  });
}
