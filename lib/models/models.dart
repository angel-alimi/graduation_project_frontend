import '../config/app_config.dart';
import 'enums.dart';

export 'enums.dart';

DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);
String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A fixed city (the `cities` table).
class City {
  final int id;
  final String nameAr;
  final String nameEn;

  const City({required this.id, required this.nameAr, required this.nameEn});

  String name(String lang) => lang == 'ar' ? nameAr : nameEn;

  factory City.fromJson(Map<String, dynamic> j) => City(
        id: j['id'] as int,
        nameAr: j['nameAr'] as String,
        nameEn: j['nameEn'] as String,
      );
}

/// A hospital from the fixed list (the `hospitals` table). Each belongs to one city.
class Hospital {
  final int id;
  final String nameAr;
  final String nameEn;
  final int cityId;

  const Hospital({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cityId,
  });

  String name(String lang) => lang == 'ar' ? nameAr : nameEn;

  factory Hospital.fromJson(Map<String, dynamic> j) => Hospital(
        id: j['id'] as int,
        nameAr: j['nameAr'] as String,
        nameEn: j['nameEn'] as String,
        cityId: j['cityId'] as int,
      );
}

/// The signed-in user (the `users` table). One account both donates and requests.
class AppUser {
  final int id;
  final String fullName;
  final String phone; // local 9 digits, e.g. 591234567
  final Gender gender;
  final DateTime birthDate;
  final int cityId;
  final BloodType bloodType;
  final DateTime? lastDonationDate;
  final int requestsCount;
  final int responsesCount;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.birthDate,
    required this.cityId,
    required this.bloodType,
    this.lastDonationDate,
    this.requestsCount = 0,
    this.responsesCount = 0,
  });

  /// Days left until the user can donate again (0 = can donate now).
  int get daysUntilEligible {
    if (lastDonationDate == null) return 0;
    final passed = DateTime.now().difference(lastDonationDate!).inDays;
    final left = AppConfig.donationCooldownDays - passed;
    return left > 0 ? left : 0;
  }

  AppUser copyWith({
    DateTime? lastDonationDate,
    int? requestsCount,
    int? responsesCount,
  }) =>
      AppUser(
        id: id,
        fullName: fullName,
        phone: phone,
        gender: gender,
        birthDate: birthDate,
        cityId: cityId,
        bloodType: bloodType,
        lastDonationDate: lastDonationDate ?? this.lastDonationDate,
        requestsCount: requestsCount ?? this.requestsCount,
        responsesCount: responsesCount ?? this.responsesCount,
      );

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        fullName: j['fullName'] as String,
        phone: j['phone'] as String,
        gender: Gender.fromApi(j['gender'] as String),
        birthDate: DateTime.parse(j['birthDate'] as String),
        cityId: j['cityId'] as int,
        bloodType: BloodType.fromApi(j['bloodType'] as String),
        lastDonationDate: _date(j['lastDonationDate']),
        requestsCount: (j['requestsCount'] ?? 0) as int,
        responsesCount: (j['responsesCount'] ?? 0) as int,
      );
}

/// What the sign-up screens collect before the OTP step.
class SignupData {
  String fullName = '';
  Gender? gender;
  DateTime? birthDate;
  int? cityId;
  BloodType bloodType = BloodType.bPos;
  DateTime? lastDonationDate; // null = never donated
  String phone = '';

  /// Terms the user ticked at sign-up (version + time), sent so the backend can prove consent.
  String? termsVersion;
  DateTime? termsAcceptedAt;

  Map<String, dynamic> toJson() => {
        'termsVersion': termsVersion,
        'termsAcceptedAt': termsAcceptedAt?.toUtc().toIso8601String(),
        'fullName': fullName,
        'gender': gender!.apiName,
        'birthDate': _ymd(birthDate!),
        'cityId': cityId,
        'bloodType': bloodType.apiName,
        'lastDonationDate': lastDonationDate == null ? null : _ymd(lastDonationDate!),
        'phone': phone,
      };
}

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        token: j['token'] as String,
        user: AppUser.fromJson(j['user'] as Map<String, dynamic>),
      );
}

/// A blood request (the `blood_requests` table). The requester is always a user.
class BloodRequest {
  final int id;
  final String requesterName;

  /// Requester's local mobile number (9 digits, e.g. 591234567), shared with matched donors.
  final String? requesterPhone;

  /// Extra numbers the requester added (e.g. a family member), local 9 digits.
  final List<String> contactPhones;
  final int hospitalId;
  final int cityId;
  final BloodType bloodType;
  final int unitsNeeded;
  final Urgency urgency;
  final String? patientName;
  final String? note;
  final RequestStatus status;
  final DateTime createdAt;

  /// When the blood is needed, in local time. Null on requests made before this field existed.
  final DateTime? neededAt;

  /// true when the signed-in user created this request.
  final bool mine;

  /// The signed-in user's response to this request, if any.
  final ResponseStatus? myResponse;

  /// On the user's own requests: donors who accepted (ACCEPTED or COMPLETED). 0 elsewhere.
  final int respondersCount;

  /// On the user's own requests: donations the requester has confirmed. 0 elsewhere.
  final int confirmedCount;

  const BloodRequest({
    required this.id,
    required this.requesterName,
    this.requesterPhone,
    this.contactPhones = const [],
    required this.hospitalId,
    required this.cityId,
    required this.bloodType,
    required this.unitsNeeded,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.patientName,
    this.note,
    this.neededAt,
    this.mine = false,
    this.myResponse,
    this.respondersCount = 0,
    this.confirmedCount = 0,
  });

  /// Every number to reach the requester on: theirs first, then the extras.
  List<String> get allPhones => {
        if ((requesterPhone ?? '').isNotEmpty) requesterPhone!,
        ...contactPhones.where((p) => p.isNotEmpty),
      }.toList();

  BloodRequest copyWith({
    RequestStatus? status,
    ResponseStatus? myResponse,
    int? respondersCount,
    int? confirmedCount,
  }) =>
      BloodRequest(
        id: id,
        requesterName: requesterName,
        requesterPhone: requesterPhone,
        contactPhones: contactPhones,
        hospitalId: hospitalId,
        cityId: cityId,
        bloodType: bloodType,
        unitsNeeded: unitsNeeded,
        urgency: urgency,
        status: status ?? this.status,
        createdAt: createdAt,
        patientName: patientName,
        note: note,
        neededAt: neededAt,
        mine: mine,
        myResponse: myResponse ?? this.myResponse,
        respondersCount: respondersCount ?? this.respondersCount,
        confirmedCount: confirmedCount ?? this.confirmedCount,
      );

  factory BloodRequest.fromJson(Map<String, dynamic> j) => BloodRequest(
        id: j['id'] as int,
        requesterName: j['requesterName'] as String,
        requesterPhone: j['requesterPhone'] as String?,
        contactPhones: ((j['contactPhones'] as List?) ?? const []).cast<String>(),
        hospitalId: j['hospitalId'] as int,
        cityId: j['cityId'] as int,
        bloodType: BloodType.fromApi(j['bloodType'] as String),
        unitsNeeded: j['unitsNeeded'] as int,
        urgency: Urgency.fromApi(j['urgency'] as String),
        patientName: j['patientName'] as String?,
        note: j['note'] as String?,
        status: RequestStatus.fromApi(j['status'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        neededAt: j['neededAt'] == null ? null : DateTime.parse(j['neededAt'] as String).toLocal(),
        mine: (j['mine'] ?? false) as bool,
        myResponse: j['myResponse'] == null
            ? null
            : ResponseStatus.fromApi(j['myResponse'] as String),
        respondersCount: (j['respondersCount'] ?? 0) as int,
        confirmedCount: (j['confirmedCount'] ?? 0) as int,
      );
}

/// A donor who accepted one of the signed-in user's requests
/// (a `request_responses` row with status ACCEPTED or COMPLETED).
class Responder {
  /// The response id, used to confirm the donation.
  final int id;
  final String donorName;

  /// Donor's local 9-digit mobile number, shared only with the requester.
  final String? donorPhone;
  final BloodType bloodType;
  final int cityId;
  final DateTime respondedAt;

  /// ACCEPTED until the requester confirms the donation, then COMPLETED.
  final ResponseStatus status;

  const Responder({
    required this.id,
    required this.donorName,
    required this.bloodType,
    required this.cityId,
    required this.respondedAt,
    required this.status,
    this.donorPhone,
  });

  bool get confirmed => status == ResponseStatus.completed;

  Responder copyWith({ResponseStatus? status}) => Responder(
        id: id,
        donorName: donorName,
        donorPhone: donorPhone,
        bloodType: bloodType,
        cityId: cityId,
        respondedAt: respondedAt,
        status: status ?? this.status,
      );

  factory Responder.fromJson(Map<String, dynamic> j) => Responder(
        id: j['id'] as int,
        donorName: j['donorName'] as String,
        donorPhone: j['donorPhone'] as String?,
        bloodType: BloodType.fromApi(j['bloodType'] as String),
        cityId: j['cityId'] as int,
        respondedAt: DateTime.parse(j['respondedAt'] as String),
        status: ResponseStatus.fromApi(j['status'] as String),
      );
}

/// Body of POST /api/requests.
class NewRequest {
  final String patientName;
  final BloodType bloodType;
  final int unitsNeeded;
  final int hospitalId;
  final Urgency urgency;
  final DateTime neededAt;
  final String? note;

  /// Optional extra contact numbers (local 9 digits). The requester's own number is always used.
  final List<String> contactPhones;

  const NewRequest({
    required this.patientName,
    required this.bloodType,
    required this.unitsNeeded,
    required this.hospitalId,
    required this.urgency,
    required this.neededAt,
    this.note,
    this.contactPhones = const [],
  });

  Map<String, dynamic> toJson() => {
        'contactPhones': contactPhones,
        'patientName': patientName.trim(),
        'bloodType': bloodType.apiName,
        'unitsNeeded': unitsNeeded,
        'hospitalId': hospitalId,
        'urgency': urgency.apiName,
        'neededAt': neededAt.toUtc().toIso8601String(),
        'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
      };
}

/// A yes/no eligibility question. Answering [disqualifyingAnswer] makes the donor ineligible.
class EligibilityQuestion {
  final int id;
  final String textAr;
  final String textEn;
  final bool disqualifyingAnswer;

  const EligibilityQuestion({
    required this.id,
    required this.textAr,
    required this.textEn,
    required this.disqualifyingAnswer,
  });

  String text(String lang) => lang == 'ar' ? textAr : textEn;

  factory EligibilityQuestion.fromJson(Map<String, dynamic> j) => EligibilityQuestion(
        id: j['id'] as int,
        textAr: j['textAr'] as String,
        textEn: j['textEn'] as String,
        disqualifyingAnswer: j['disqualifyingAnswer'] as bool,
      );
}

/// An in-app notification. The app writes the text from [type] and the fields below,
/// so the backend does not need to store translated text.
class AppNotification {
  final int id;
  final NotificationType type;
  final int? requestId;
  final BloodType? bloodType;
  final int? hospitalId;
  final String? personName;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.requestId,
    this.bloodType,
    this.hospitalId,
    this.personName,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        type: NotificationType.fromApi(j['type'] as String),
        requestId: j['requestId'] as int?,
        bloodType: j['bloodType'] == null ? null : BloodType.fromApi(j['bloodType'] as String),
        hospitalId: j['hospitalId'] as int?,
        personName: j['personName'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        read: (j['read'] ?? false) as bool,
      );
}

String formatYmd(DateTime d) => _ymd(d);

String formatDate(DateTime d, String lang) {
  const ar = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final m = (lang == 'ar' ? ar : en)[d.month - 1];
  return '${d.day} $m ${d.year}';
}

/// 12-hour time with the app's Latin digits, e.g. 2:05 م or 2:05 PM.
String formatTime(int hour, int minute, String lang) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  final pm = hour >= 12;
  final suffix = lang == 'ar' ? (pm ? 'م' : 'ص') : (pm ? 'PM' : 'AM');
  return '$h:${minute.toString().padLeft(2, '0')} $suffix';
}

String formatDateTime(DateTime d, String lang) =>
    '${formatDate(d, lang)} · ${formatTime(d.hour, d.minute, lang)}';

/// One past donation in the user's donation record.
class Donation {
  final int id;
  final DateTime date;

  /// Where the user donated, when known.
  final int? hospitalId;

  const Donation({required this.id, required this.date, this.hospitalId});

  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
        id: j['id'] as int,
        date: DateTime.parse(j['date'] as String),
        hospitalId: j['hospitalId'] as int?,
      );
}
