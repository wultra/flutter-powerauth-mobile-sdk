
/// The `PowerAuthUserInfo` object contains additional information about the end-user.
class PowerAuthUserInfo {

  /// Map with all claims representing information about the user.
  final Map _claims;
  /// Optional address of the end-user.
  final PowerAuthUserAddress? userAddress;

  /// Construct object with map with claims.
  /// [claims] Map with all claims representing information about the user.
  PowerAuthUserInfo(Map? claims)
      : _claims = claims ?? {},
        userAddress = claims?['address'] is Map<String, dynamic>
            ? PowerAuthUserAddress(claims!['address'] as Map<String, dynamic>)
            : null;

  /// Full collection of claims received from the server.
  Map get allClaims => _claims;

  /// The subject (end-user) identifier.
  String? get subject => _claims['sub'] as String?;

  /// The full name of the end-user.
  String? get name => _claims['name'] as String?;

  /// The given or first name of the end-user.
  String? get givenName => _claims['given_name'] as String?;

  /// The surname(s) or last name(s) of the end-user.
  String? get familyName => _claims['family_name'] as String?;

  /// The middle name of the end-user.
  String? get middleName => _claims['middle_name'] as String?;

  /// The casual name of the end-user.
  String? get nickname => _claims['nickname'] as String?;

  /// The username by which the end-user wants to be referred to at the client application.
  String? get preferredUsername => _claims['preferred_username'] as String?;

  /// The URL of the profile page for the end-user.
  String? get profileUrl => _claims['profile'] as String?;

  /// The URL of the profile picture for the end-user.
  String? get pictureUrl => _claims['picture'] as String?;

  /// The URL of the end-user's web page or blog.
  String? get websiteUrl => _claims['website'] as String?;

  /// The end-user's preferred email address.
  String? get email => _claims['email'] as String?;

  /// `true` if the end-user's email address has been verified, else `false`.
  bool get isEmailVerified => _claims['email_verified'] == true;

  /// The end-user's preferred telephone number.
  String? get phoneNumber => _claims['phone_number'] as String?;

  /// `true` if the end-user's telephone number has been verified, else `false`.
  bool get isPhoneNumberVerified => _claims['phone_number_verified'] == true;

  /// The end-user's gender.
  String? get gender => _claims['gender'] as String?;

  /// The end-user's time zone.
  String? get zoneInfo => _claims['zoneinfo'] as String?;

  /// The end-user's locale, represented as a BCP47 language tag.
  String? get locale => _claims['locale'] as String?;

  /// Time the end-user's information was last updated.
  DateTime? get updatedAt => _parseTimestamp(_claims['updated_at']);

  /// The end-user's birthdate.
  DateTime? get birthdate => _parseDate(_claims['birthdate']);
}

/// The `PowerAuthUserAddress` object contains address of end-user.
class PowerAuthUserAddress {

  /// Map with all claims representing information about the user's address.
  final Map<String, dynamic> _claims;

  /// Construct object with map with claims.
  /// [claims] Map with all claims representing information about the user's address.
  PowerAuthUserAddress(Map<String, dynamic>? claims) : _claims = claims ?? {};

  /// Full collection of claims received from the server.
  Map<String, dynamic> get allClaims => _claims;

  /// The full mailing address, with multiple lines if necessary.
  String? get formatted => (_claims['formatted'] as String?)?.valueAsMultilineString();

  /// The street address component, which may include house number, street name, post office box,
  /// and other multi-line information.
  String? get street => (_claims['street_address'] as String?)?.valueAsMultilineString();

  /// City or locality component.
  String? get locality => _claims['locality'] as String?;

  /// State, province, prefecture or region component.
  String? get region => _claims['region'] as String?;

  /// Zip code or postal code component.
  String? get postalCode => _claims['postal_code'] as String?;

  /// Country name component.
  String? get country => _claims['country'] as String?;
}

DateTime? _parseTimestamp(dynamic value) {
  if (value is int) {
    // Assume seconds since epoch
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  if (value is String) {
    final intVal = int.tryParse(value);
    if (intVal != null) {
      return DateTime.fromMillisecondsSinceEpoch(intVal * 1000, isUtc: true);
    }
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is String) {
    try {
      // Expecting format yyyy-MM-dd
      final parts = value.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
  }
  return null;
}

extension on String {
  String valueAsMultilineString() {
    return replaceAll("\r\n", "\n");
  }
}