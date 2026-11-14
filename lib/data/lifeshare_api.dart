import '../models/models.dart';

/// Everything the app needs from the backend.
///
/// Two implementations:
/// - [RemoteApi] (remote_api.dart) calls the Spring Boot REST API.
/// - [MockApi]   (mock_api.dart)   keeps sample data in memory, so the app runs with no backend.
///
/// The endpoint for each method is listed in API_CONTRACT.md.
abstract class LifeShareApi {
  /// Saves the JWT so later calls send `Authorization: Bearer <token>`.
  void setToken(String? token);

  // Lookups
  Future<List<City>> getCities();
  Future<List<Hospital>> getHospitals();

  // Auth (phone + OTP)
  Future<void> requestOtp(String phone, OtpPurpose purpose);
  Future<AuthResult> signup(SignupData data, String code);
  Future<AuthResult> login(String phone, String code);
  Future<AppUser> me();
  Future<AppUser> updateLastDonation(DateTime date);

  /// The signed-in user's donation record, newest first.
  Future<List<Donation>> donations();

  // Requests
  Future<List<BloodRequest>> feed({String? query});
  Future<List<BloodRequest>> myRequests();
  Future<List<BloodRequest>> matchedRequests();

  /// Requests the user accepted (any status, so fulfilled or cancelled ones
  /// stay visible), newest first.
  Future<List<BloodRequest>> acceptedRequests();
  Future<BloodRequest> createRequest(NewRequest request);
  Future<void> cancelRequest(int requestId);

  // Responding to a request
  Future<List<EligibilityQuestion>> eligibilityQuestions();

  /// Sends the eligibility answers. The backend decides ACCEPTED or INELIGIBLE.
  Future<ResponseStatus> respond(int requestId, Map<int, bool> answers);

  // Responders to the user's own request
  /// Donors who accepted [requestId] (ACCEPTED or COMPLETED), newest first. Owner only.
  Future<List<Responder>> responders(int requestId);

  /// The requester confirms that a responder donated. Returns the updated responder (COMPLETED).
  Future<Responder> confirmDonation(int requestId, int responseId);

  // Notifications
  Future<List<AppNotification>> notifications();
  Future<void> markAllNotificationsRead();
}

/// An error the screens can show to the user.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
