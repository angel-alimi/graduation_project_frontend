import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeshare/core/search.dart';
import 'package:lifeshare/data/palestine_data.dart';
import 'package:lifeshare/models/models.dart';
import 'package:lifeshare/widgets/bottom_bar.dart';

void main() {
  group('Predefined lists', () {
    test('cities are only the 16 governorate main cities', () {
      expect(kCities.length, 16);
      expect(kCities.map((c) => c.nameEn), containsAll(['Ramallah', 'Jerusalem', 'Gaza City', 'Salfit', 'Tubas', 'Jabalia']));
      expect(kCities.map((c) => c.nameEn), isNot(contains('Birzeit')));
    });
    test('ids are unique and every hospital has a real city', () {
      final cityIds = kCities.map((c) => c.id).toSet();
      final hospitalIds = kHospitals.map((h) => h.id).toSet();
      expect(cityIds.length, kCities.length);
      expect(hospitalIds.length, kHospitals.length);
      for (final h in kHospitals) {
        expect(cityIds, contains(h.cityId), reason: h.nameEn);
      }
    });
  });

  group('Search', () {
    test('ignores Arabic spelling variants and case', () {
      expect(searchScore('أريحا Jericho', 'اريحا'), isNotNull);
      expect(searchScore('قلقيلية Qalqilya', 'قلقيليه'), isNotNull);
      expect(searchScore('رام الله Ramallah', 'RAMA'), isNotNull);
      expect(searchScore('رام الله Ramallah', 'نابلس'), isNull);
    });
    test('words match in any order and prefixes rank first', () {
      expect(searchScore('مستشفى الحسين الحكومي', 'الحكومي الحسين'), isNotNull);
      expect(searchScore('بيت لحم', 'بيت')!, lessThan(searchScore('دير بيت', 'يت')!));
    });
  });

  group('Sign up', () {
    SignupData data() => SignupData()
      ..fullName = 'أمل'
      ..gender = Gender.female
      ..birthDate = DateTime(2002, 7, 5)
      ..cityId = 1;

    test('sends the last donation date when given', () {
      final d = data()..lastDonationDate = DateTime(2026, 10, 1);
      expect(d.toJson()['lastDonationDate'], '2026-10-01');
    });
    test('sends null when the user never donated', () {
      expect(data().toJson()['lastDonationDate'], isNull);
    });
  });

  group('Request date and time', () {
    test('neededAt is sent in UTC and read back as the same moment in local time', () {
      final at = DateTime(2026, 11, 5, 14, 30);
      final json = NewRequest(
        patientName: 'مريم',
        bloodType: BloodType.oPos,
        unitsNeeded: 1,
        hospitalId: 1,
        neededAt: at,
        contactPhone: '591234567',
      ).toJson();
      expect(json['contactPhone'], '591234567');
      expect((json['neededAt'] as String).endsWith('Z'), isTrue);
      final r = BloodRequest.fromJson({
        'id': 1, 'requesterName': 'x', 'hospitalId': 1, 'cityId': 1, 'bloodType': 'O_POS', 'unitsNeeded': 1,
        'status': 'OPEN', 'createdAt': '2026-11-04T16:20:00+02:00', 'neededAt': json['neededAt'],
      });
      expect(r.neededAt, at);
      expect(r.neededAt!.isUtc, isFalse);
      expect(r.copyWith(status: RequestStatus.cancelled).neededAt, at);
    });
    test('requests without neededAt still load', () {
      final r = BloodRequest.fromJson({
        'id': 1, 'requesterName': 'x', 'hospitalId': 1, 'cityId': 1, 'bloodType': 'O_POS', 'unitsNeeded': 1,
        'status': 'OPEN', 'createdAt': '2026-11-04T16:20:00+02:00',
      });
      expect(r.neededAt, isNull);
    });
    test('time is 12-hour in both languages', () {
      expect(formatTime(0, 5, 'en'), '12:05 AM');
      expect(formatTime(12, 0, 'en'), '12:00 PM');
      expect(formatTime(14, 30, 'ar'), '2:30 م');
      expect(formatTime(9, 0, 'ar'), '9:00 ص');
    });
  });

  group('Bottom bar', () {
    var plus = 0, bell = 0;
    final items = [
      const BottomBarItem(Icons.home_outlined, 'الرئيسية'),
      const BottomBarItem(Icons.article_outlined, 'المنشورات'),
      BottomBarItem.action(Icons.add_rounded, 'طلب جديد', () => plus++, primary: true),
      BottomBarItem.action(Icons.notifications_none_rounded, 'الإشعارات', () => bell++),
      const BottomBarItem(Icons.settings_outlined, 'الإعدادات'),
    ];
    const tabs = {0: Icons.home_outlined, 1: Icons.article_outlined, 4: Icons.settings_outlined};

    Future<void> pump(WidgetTester tester, TextDirection dir, int index, [ValueChanged<int>? onTap]) async {
      await tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: dir,
          child: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: LifeShareBottomBar(items: items, index: index, onTap: onTap ?? (_) {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    for (final dir in TextDirection.values) {
      testWidgets('active icon is centered in the red circle ($dir)', (tester) async {
        for (final e in tabs.entries) {
          await pump(tester, dir, e.key);
          final circle = tester.getCenter(find.byKey(const ValueKey('bar-indicator')));
          final icon = tester.getCenter(find.byIcon(e.value));
          expect((icon.dx - circle.dx).abs(), lessThan(0.01));
          expect((icon.dy - circle.dy).abs(), lessThan(0.01));
        }
      });

      testWidgets('slots keep their order; + and bell run their actions ($dir)', (tester) async {
        int? tapped;
        plus = 0;
        bell = 0;
        await pump(tester, dir, 0, (i) => tapped = i);
        final xs = [
          for (final i in [Icons.home_outlined, Icons.article_outlined, Icons.add_rounded, Icons.notifications_none_rounded, Icons.settings_outlined])
            tester.getCenter(find.byIcon(i)).dx,
        ];
        expect(xs, [...xs]..sort(), reason: 'left-to-right in both languages');
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.tap(find.byIcon(Icons.notifications_none_rounded));
        expect([plus, bell, tapped], [1, 1, null]);
        await tester.tap(find.byIcon(Icons.settings_outlined));
        expect(tapped, 4);
      });
    }
  });
}
