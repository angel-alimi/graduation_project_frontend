import '../models/models.dart';
import 'lifeshare_api.dart';
import 'palestine_data.dart';

/// In-memory backend with sample data, so the app works before the Spring Boot API exists.
/// Any 6-digit code is accepted as the OTP.
class MockApi implements LifeShareApi {
  final _delay = const Duration(milliseconds: 350);
  Future<void> _wait() => Future.delayed(_delay);

  int _nextId = 100;
  AppUser? _user;
  final Set<int> _readNotifications = {};
  bool _allRead = false;

  static const _questions = [
    EligibilityQuestion(
        id: 1,
        textAr: 'هل تبرعت بالدم خلال آخر 56 يوماً؟',
        textEn: 'Have you donated blood in the last 56 days?',
        disqualifyingAnswer: true),
    EligibilityQuestion(
        id: 2,
        textAr: 'هل تتناول مضاداً حيوياً حالياً؟',
        textEn: 'Are you taking antibiotics right now?',
        disqualifyingAnswer: true),
    EligibilityQuestion(
        id: 3,
        textAr: 'هل وزنك أقل من 50 كغ؟',
        textEn: 'Do you weigh less than 50 kg?',
        disqualifyingAnswer: true),
  ];

  late final List<BloodRequest> _requests = [
    BloodRequest(
        id: 1,
        requesterName: 'نور أ.',
        hospitalId: 1,
        cityId: 1,
        bloodType: BloodType.oPos,
        unitsNeeded: 3,
        urgency: Urgency.urgent,
        note: 'مريض في العناية المركزة.',
        status: RequestStatus.open,
        neededAt: DateTime.now().add(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 18))),
    BloodRequest(
        id: 2,
        requesterName: 'سارة ك.',
        hospitalId: 1,
        cityId: 1,
        bloodType: BloodType.bPos,
        unitsNeeded: 2,
        urgency: Urgency.urgent,
        patientName: 'مريم خليل',
        note: 'قبل عملية غداً صباحاً.',
        status: RequestStatus.open,
        neededAt: DateTime.now().add(const Duration(hours: 16)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
    BloodRequest(
        id: 3,
        requesterName: 'أحمد ر.',
        hospitalId: 2,
        cityId: 1,
        bloodType: BloodType.aPos,
        unitsNeeded: 2,
        urgency: Urgency.normal,
        note: 'لإجراء عملية جراحية.',
        status: RequestStatus.open,
        neededAt: DateTime.now().add(const Duration(hours: 28)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3))),
    BloodRequest(
        id: 4,
        requesterName: 'ليان ش.',
        hospitalId: 3,
        cityId: 2,
        bloodType: BloodType.bNeg,
        unitsNeeded: 1,
        urgency: Urgency.normal,
        note: 'مريضة غسيل كلى.',
        status: RequestStatus.open,
        neededAt: DateTime.now().add(const Duration(hours: 50)),
        createdAt: DateTime.now().subtract(const Duration(hours: 9))),
    BloodRequest(
        id: 5,
        requesterName: 'خالد م.',
        hospitalId: 2,
        cityId: 1,
        bloodType: BloodType.abPos,
        unitsNeeded: 1,
        urgency: Urgency.normal,
        note: 'طفل يحتاج نقل دم دوري.',
        status: RequestStatus.open,
        neededAt: DateTime.now().add(const Duration(hours: 75)),
        createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ];

  AppUser _requireUser() {
    final u = _user;
    if (u == null) throw const ApiException('unauthorized', statusCode: 401);
    return u;
  }

  AppUser _withCounts(AppUser u) => u.copyWith(
        requestsCount: _requests.where((r) => r.mine && r.status != RequestStatus.cancelled).length,
        responsesCount: _requests.where((r) => r.myResponse == ResponseStatus.accepted).length,
      );

  @override
  void setToken(String? token) {
    if (token == null) _user = null;
    // A saved token from an earlier run signs the sample user back in.
    if (token != null && _user == null) {
      _user = AppUser(
        id: 1,
        fullName: 'أمل',
        phone: '590000000',
        gender: Gender.female,
        birthDate: DateTime(2002, 7, 5),
        cityId: 1,
        bloodType: BloodType.bPos,
      );
    }
  }

  @override
  Future<List<City>> getCities() async {
    await _wait();
    return kCities;
  }

  @override
  Future<List<Hospital>> getHospitals() async {
    await _wait();
    return kHospitals;
  }

  @override
  Future<void> requestOtp(String phone, OtpPurpose purpose) async {
    await _wait();
  }

  void _checkCode(String code) {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const ApiException('invalid_code', statusCode: 400);
    }
  }

  @override
  Future<AuthResult> signup(SignupData data, String code) async {
    await _wait();
    _checkCode(code);
    _user = AppUser(
      id: 1,
      fullName: data.fullName,
      phone: data.phone,
      gender: data.gender!,
      birthDate: data.birthDate!,
      cityId: data.cityId!,
      bloodType: data.bloodType,
      lastDonationDate: data.lastDonationDate,
    );
    return AuthResult(token: 'mock-token', user: _user!);
  }

  @override
  Future<AuthResult> login(String phone, String code) async {
    await _wait();
    _checkCode(code);
    _user = AppUser(
      id: 1,
      fullName: 'أمل',
      phone: phone,
      gender: Gender.female,
      birthDate: DateTime(2002, 7, 5),
      cityId: 1,
      bloodType: BloodType.bPos,
    );
    return AuthResult(token: 'mock-token', user: _user!);
  }

  @override
  Future<AppUser> me() async {
    await _wait();
    return _withCounts(_requireUser());
  }

  @override
  Future<AppUser> updateLastDonation(DateTime date) async {
    await _wait();
    _user = _requireUser().copyWith(lastDonationDate: date);
    return _withCounts(_user!);
  }

  @override
  Future<List<BloodRequest>> feed({Urgency? urgency, String? query}) async {
    await _wait();
    final q = (query ?? '').trim().toLowerCase();
    return _requests.where((r) {
      if (r.status != RequestStatus.open) return false;
      if (urgency != null && r.urgency != urgency) return false;
      if (q.isEmpty) return true;
      final h = kHospitals.firstWhere((x) => x.id == r.hospitalId);
      final c = kCities.firstWhere((x) => x.id == r.cityId);
      final hay = [r.requesterName, r.note ?? '', r.bloodType.label, h.nameAr, h.nameEn, c.nameAr, c.nameEn]
          .join(' ')
          .toLowerCase();
      return hay.contains(q);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<BloodRequest>> myRequests() async {
    await _wait();
    return _requests.where((r) => r.mine && r.status != RequestStatus.cancelled).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<BloodRequest>> matchedRequests() async {
    await _wait();
    final u = _requireUser();
    return _requests
        .where((r) => !r.mine && r.status == RequestStatus.open && u.bloodType.canGiveTo(r.bloodType))
        .toList();
  }

  @override
  Future<BloodRequest> createRequest(NewRequest request) async {
    await _wait();
    final u = _requireUser();
    final h = kHospitals.firstWhere((x) => x.id == request.hospitalId);
    final r = BloodRequest(
      id: _nextId++,
      requesterName: u.fullName,
      hospitalId: h.id,
      cityId: h.cityId,
      bloodType: request.bloodType,
      unitsNeeded: request.unitsNeeded,
      urgency: request.urgency,
      neededAt: request.neededAt,
      patientName: request.patientName,
      note: request.note,
      status: RequestStatus.open,
      createdAt: DateTime.now(),
      mine: true,
    );
    _requests.insert(0, r);
    return r;
  }

  @override
  Future<void> cancelRequest(int requestId) async {
    await _wait();
    final i = _requests.indexWhere((r) => r.id == requestId);
    if (i >= 0) _requests[i] = _requests[i].copyWith(status: RequestStatus.cancelled);
  }

  @override
  Future<List<EligibilityQuestion>> eligibilityQuestions() async {
    await _wait();
    return _questions;
  }

  @override
  Future<ResponseStatus> respond(int requestId, Map<int, bool> answers) async {
    await _wait();
    final ineligible = _questions.any((q) => answers[q.id] == q.disqualifyingAnswer);
    final status = ineligible ? ResponseStatus.ineligible : ResponseStatus.accepted;
    final i = _requests.indexWhere((r) => r.id == requestId);
    if (i >= 0) _requests[i] = _requests[i].copyWith(myResponse: status);
    return status;
  }

  @override
  Future<List<AppNotification>> notifications() async {
    await _wait();
    final u = _requireUser();
    final list = <AppNotification>[];
    for (final r in _requests.where((r) => r.mine && r.status == RequestStatus.open)) {
      list.add(AppNotification(
          id: 1000 + r.id,
          type: NotificationType.requestPosted,
          requestId: r.id,
          bloodType: r.bloodType,
          hospitalId: r.hospitalId,
          createdAt: r.createdAt));
    }
    final match = _requests
        .where((r) => !r.mine && r.status == RequestStatus.open && u.bloodType.canGiveTo(r.bloodType))
        .toList();
    if (match.isNotEmpty) {
      final m = match.first;
      list.add(AppNotification(
          id: 1,
          type: NotificationType.match,
          requestId: m.id,
          bloodType: m.bloodType,
          hospitalId: m.hospitalId,
          personName: m.requesterName,
          createdAt: m.createdAt));
    }
    list.add(AppNotification(
        id: 2, type: NotificationType.reminder, createdAt: DateTime.now().subtract(const Duration(days: 1))));
    list.add(AppNotification(
        id: 3, type: NotificationType.welcome, createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2))));
    return list
        .map((n) => AppNotification(
              id: n.id,
              type: n.type,
              requestId: n.requestId,
              bloodType: n.bloodType,
              hospitalId: n.hospitalId,
              personName: n.personName,
              createdAt: n.createdAt,
              read: _allRead || _readNotifications.contains(n.id),
            ))
        .toList();
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _wait();
    _allRead = true;
  }
}
