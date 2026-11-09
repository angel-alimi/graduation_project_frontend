import 'package:flutter_test/flutter_test.dart';
import 'package:lifeshare/data/mock_api.dart';
import 'package:lifeshare/models/models.dart';

void main() {
  group('Responders', () {
    test('requester sees responders and confirming enough donations fulfils the request', () async {
      final api = MockApi()..setToken('t');
      final r = await api.createRequest(NewRequest(
        patientName: 'مريم',
        bloodType: BloodType.bPos,
        unitsNeeded: 2,
        hospitalId: 1,
        urgency: Urgency.normal,
        neededAt: DateTime.now().add(const Duration(hours: 4)),
      ));
      final list = await api.responders(r.id);
      expect(list, isNotEmpty);
      expect(list.every((d) => d.bloodType.canGiveTo(BloodType.bPos)), isTrue);
      expect(list.every((d) => !d.confirmed), isTrue);

      final first = await api.confirmDonation(r.id, list[0].id);
      expect(first.status, ResponseStatus.completed);
      var mine = (await api.myRequests()).firstWhere((x) => x.id == r.id);
      expect(mine.confirmedCount, 1);
      expect(mine.status, RequestStatus.open);

      await api.confirmDonation(r.id, list[1].id);
      mine = (await api.myRequests()).firstWhere((x) => x.id == r.id);
      expect(mine.confirmedCount, 2);
      expect(mine.status, RequestStatus.fulfilled);
    });

    test('Responder reads the API shape', () {
      final d = Responder.fromJson({
        'id': 5, 'donorName': 'محمد', 'donorPhone': '599876543', 'bloodType': 'O_NEG',
        'cityId': 1, 'respondedAt': '2026-11-04T16:20:00+02:00', 'status': 'COMPLETED',
      });
      expect(d.confirmed, isTrue);
      expect(d.bloodType, BloodType.oNeg);
    });
  });
}
