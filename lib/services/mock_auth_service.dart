import '../models/auth_response.dart';
import '../models/user_role.dart';

/// Session-scoped "database" mapping email → role, so the smart router on
/// the login page has something real to look up. Seeded with one demo
/// account per public role; every sign-up during this session also
/// registers itself here, so signing up and then logging back in with the
/// same email correctly round-trips to the same workspace.
///
/// TODO: replace with a real `GET /api/users/me` (or equivalent) once the
/// backend in /backend is deployed — [MockAuthService] below is shaped to
/// make that swap a drop-in.
final Map<String, UserRole> _accountDirectory = {
  'visitor@onsite.demo': UserRole.user,
  'affiliater@onsite.demo': UserRole.affiliater,
  'agent@onsite.demo': UserRole.agent,
  'investor@onsite.demo': UserRole.investor,
  'admin@onsite.demo': UserRole.admin,
};

class MockAuthService {
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required UserRole role,
    String? phone,
    String? agencyOrLicense,
    bool interestedInFractionalInvesting = false,
    String? referralCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _accountDirectory[email.trim().toLowerCase()] = role;
    return AppUser(
      id: 'demo-${role.apiValue}-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim().isEmpty ? role.label : fullName.trim(),
      email: email.trim(),
      role: role,
      phone: phone?.trim(),
      agencyOrLicense: (agencyOrLicense?.trim().isEmpty ?? true) ? null : agencyOrLicense!.trim(),
      interestedInFractionalInvesting: interestedInFractionalInvesting,
      referralCode: (referralCode?.trim().isEmpty ?? true) ? null : referralCode!.trim(),
    );
  }

  /// Explicit-role sign in — used only by the Admin portal, which isn't
  /// part of the smart-routed public login (an account's admin status
  /// shouldn't be guessable from a generic email/password form).
  Future<AppUser> signIn({
    required String email,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return AppUser(
      id: 'demo-${role.apiValue}-${DateTime.now().millisecondsSinceEpoch}',
      fullName: _nameFromEmail(email, role),
      email: email.trim(),
      role: role,
    );
  }

  /// The standard public login: authenticate, then look up whatever role
  /// this account was saved under and let the caller route accordingly.
  /// Unrecognized emails default to Visitor — the safe, browse-only role.
  Future<AppUser> login({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final role = _accountDirectory[email.trim().toLowerCase()] ?? UserRole.user;
    return AppUser(
      id: 'demo-${role.apiValue}-${DateTime.now().millisecondsSinceEpoch}',
      fullName: _nameFromEmail(email, role),
      email: email.trim(),
      role: role,
    );
  }

  String _nameFromEmail(String email, UserRole role) {
    final name = email.contains('@') ? email.split('@').first : email;
    return name.isEmpty ? role.label : _titleCase(name);
  }

  String _titleCase(String s) => s
      .replaceAll(RegExp(r'[._-]'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
