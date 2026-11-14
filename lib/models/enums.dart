
library;

enum BloodType {
  aPos('A+', 'A_POS'),
  aNeg('A-', 'A_NEG'),
  bPos('B+', 'B_POS'),
  bNeg('B-', 'B_NEG'),
  abPos('AB+', 'AB_POS'),
  abNeg('AB-', 'AB_NEG'),
  oPos('O+', 'O_POS'),
  oNeg('O-', 'O_NEG');

  const BloodType(this.label, this.apiName);
  final String label;
  final String apiName;

  String get display => label.replaceAll('-', '−');

  static BloodType fromApi(String value) => BloodType.values.firstWhere(
        (b) => b.apiName == value || b.label == value,
        orElse: () => BloodType.oPos,
      );

  /// Recipient types this donor type can give red cells to.
  List<BloodType> get canDonateTo {
    switch (this) {
      case BloodType.oNeg:
        return BloodType.values;
      case BloodType.oPos:
        return [oPos, aPos, bPos, abPos];
      case BloodType.aNeg:
        return [aNeg, aPos, abNeg, abPos];
      case BloodType.aPos:
        return [aPos, abPos];
      case BloodType.bNeg:
        return [bNeg, bPos, abNeg, abPos];
      case BloodType.bPos:
        return [bPos, abPos];
      case BloodType.abNeg:
        return [abNeg, abPos];
      case BloodType.abPos:
        return [abPos];
    }
  }

  bool canGiveTo(BloodType recipient) => canDonateTo.contains(recipient);
}

enum Gender {
  female('FEMALE'),
  male('MALE');

  const Gender(this.apiName);
  final String apiName;

  static Gender fromApi(String value) =>
      Gender.values.firstWhere((g) => g.apiName == value, orElse: () => Gender.female);
}

enum RequestStatus {
  open('OPEN'),
  fulfilled('FULFILLED'),
  cancelled('CANCELLED');

  const RequestStatus(this.apiName);
  final String apiName;

  static RequestStatus fromApi(String value) => RequestStatus.values
      .firstWhere((s) => s.apiName == value, orElse: () => RequestStatus.open);
}

/// Matches the request_responses.status values agreed for the database.
enum ResponseStatus {
  accepted('ACCEPTED'),
  declined('DECLINED'),
  ineligible('INELIGIBLE'),
  cancelled('CANCELLED'),
  completed('COMPLETED');

  const ResponseStatus(this.apiName);
  final String apiName;

  static ResponseStatus fromApi(String value) => ResponseStatus.values
      .firstWhere((s) => s.apiName == value, orElse: () => ResponseStatus.accepted);
}

enum OtpPurpose {
  signup('SIGNUP'),
  login('LOGIN');

  const OtpPurpose(this.apiName);
  final String apiName;
}

enum NotificationType {
  match('MATCH'),
  requestPosted('REQUEST_POSTED'),
  reminder('REMINDER'),
  welcome('WELCOME');

  const NotificationType(this.apiName);
  final String apiName;

  static NotificationType fromApi(String value) => NotificationType.values
      .firstWhere((n) => n.apiName == value, orElse: () => NotificationType.welcome);
}
