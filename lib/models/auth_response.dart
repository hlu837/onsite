import 'user_role.dart';

/// The signed-in user for this demo session. No backend — created locally
/// by [MockAuthService] the moment someone submits sign in / sign up.
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;

  /// Agent / Broker only — agency name or license/ID number, captured at
  /// signup to signal a professional verification process.
  final String? agencyOrLicense;

  /// Investor only — opted in to fractional property investment updates.
  final bool interestedInFractionalInvesting;

  /// Optional — who gets affiliate credit for this signup.
  final String? referralCode;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.agencyOrLicense,
    this.interestedInFractionalInvesting = false,
    this.referralCode,
  });
}
