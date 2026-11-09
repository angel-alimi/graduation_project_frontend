import 'package:flutter_test/flutter_test.dart';
import 'package:lifeshare/models/enums.dart';
import 'package:lifeshare/widgets/inputs.dart';

void main() {
  group('Blood compatibility', () {
    test('O- can donate to everyone', () {
      for (final t in BloodType.values) {
        expect(BloodType.oNeg.canGiveTo(t), isTrue);
      }
    });
    test('B+ can donate to B+ and AB+ only', () {
      expect(BloodType.bPos.canDonateTo, [BloodType.bPos, BloodType.abPos]);
    });
    test('API names round-trip', () {
      for (final t in BloodType.values) {
        expect(BloodType.fromApi(t.apiName), t);
      }
    });
  });

  group('Phone numbers', () {
    test('normalises common formats', () {
      expect(normalizePhone('0591234567'), '591234567');
      expect(normalizePhone('+970 59 123 4567'), '591234567');
    });
    test('validates Palestinian mobiles', () {
      expect(isValidPhone('0591234567'), isTrue);
      expect(isValidPhone('0561234567'), isTrue);
      expect(isValidPhone('0521234567'), isFalse);
      expect(isValidPhone('59123'), isFalse);
    });
  });
}
