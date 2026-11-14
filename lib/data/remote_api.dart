import '../models/models.dart';
import 'api_client.dart';
import 'lifeshare_api.dart';

/// Calls the Spring Boot backend. Paths and JSON shapes are documented in API_CONTRACT.md.
class RemoteApi implements LifeShareApi {
  RemoteApi(this.client);
  final ApiClient client;

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) =>
      (data as List).map((e) => f(e as Map<String, dynamic>)).toList();

  @override
  void setToken(String? token) => client.token = token;

  // ---------- lookups ----------
  @override
  Future<List<City>> getCities() async => _list(await client.get('/api/cities'), City.fromJson);

  @override
  Future<List<Hospital>> getHospitals() async =>
      _list(await client.get('/api/hospitals'), Hospital.fromJson);

  // ---------- auth ----------
  @override
  Future<void> requestOtp(String phone, OtpPurpose purpose) async {
    await client.post('/api/auth/otp', {'phone': phone, 'purpose': purpose.apiName});
  }

  @override
  Future<AuthResult> signup(SignupData data, String code) async {
    final res = await client.post('/api/auth/signup', {...data.toJson(), 'code': code});
    return AuthResult.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<AuthResult> login(String phone, String code) async {
    final res = await client.post('/api/auth/login', {'phone': phone, 'code': code});
    return AuthResult.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<AppUser> me() async =>
      AppUser.fromJson(await client.get('/api/users/me') as Map<String, dynamic>);

  @override
  Future<AppUser> updateLastDonation(DateTime date) async => AppUser.fromJson(
        await client.patch('/api/users/me', {'lastDonationDate': formatYmd(date)})
            as Map<String, dynamic>,
      );

  @override
  Future<List<Donation>> donations() async =>
      _list(await client.get('/api/users/me/donations'), Donation.fromJson);

  // ---------- requests ----------
  @override
  Future<List<BloodRequest>> feed({String? query}) async => _list(
        await client.get('/api/requests', query: {'q': query}),
        BloodRequest.fromJson,
      );

  @override
  Future<List<BloodRequest>> myRequests() async =>
      _list(await client.get('/api/requests/mine'), BloodRequest.fromJson);

  @override
  Future<List<BloodRequest>> matchedRequests() async =>
      _list(await client.get('/api/requests/matched'), BloodRequest.fromJson);

  @override
  Future<List<BloodRequest>> acceptedRequests() async =>
      _list(await client.get('/api/requests/accepted'), BloodRequest.fromJson);

  @override
  Future<BloodRequest> createRequest(NewRequest request) async => BloodRequest.fromJson(
        await client.post('/api/requests', request.toJson()) as Map<String, dynamic>,
      );

  @override
  Future<void> cancelRequest(int requestId) async {
    await client.patch('/api/requests/$requestId/cancel');
  }

  // ---------- responses ----------
  @override
  Future<List<EligibilityQuestion>> eligibilityQuestions() async =>
      _list(await client.get('/api/eligibility-questions'), EligibilityQuestion.fromJson);

  @override
  Future<ResponseStatus> respond(int requestId, Map<int, bool> answers) async {
    final res = await client.post('/api/requests/$requestId/responses', {
      'answers': answers.entries
          .map((e) => {'questionId': e.key, 'answer': e.value})
          .toList(),
    }) as Map<String, dynamic>;
    return ResponseStatus.fromApi(res['status'] as String);
  }

  @override
  Future<List<Responder>> responders(int requestId) async =>
      _list(await client.get('/api/requests/$requestId/responses'), Responder.fromJson);

  @override
  Future<Responder> confirmDonation(int requestId, int responseId) async => Responder.fromJson(
        await client.post('/api/requests/$requestId/responses/$responseId/confirm')
            as Map<String, dynamic>,
      );

  // ---------- notifications ----------
  @override
  Future<List<AppNotification>> notifications() async =>
      _list(await client.get('/api/notifications'), AppNotification.fromJson);

  @override
  Future<void> markAllNotificationsRead() async {
    await client.post('/api/notifications/read-all');
  }
}
