/// Password rules enforced by Supabase Auth on this project.
///
/// The client used to check the length only, so a password like `azerty`
/// passed validation and the server then rejected the signup with an opaque
/// HTTP 422 `weak_password`. Keep this in sync with
/// Dashboard > Authentication > Policies.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 6;

  /// Symbol set accepted by Supabase.
  static final RegExp _symbol = RegExp(r'''[!@#$%^&*()_+\-=\[\]{};'\\:"|<>?,./`~]''');
  static final RegExp _lowercase = RegExp('[a-z]');
  static final RegExp _uppercase = RegExp('[A-Z]');
  static final RegExp _digit = RegExp('[0-9]');

  static bool hasMinLength(String value) => value.length >= minLength;
  static bool hasLowercase(String value) => _lowercase.hasMatch(value);
  static bool hasUppercase(String value) => _uppercase.hasMatch(value);
  static bool hasDigit(String value) => _digit.hasMatch(value);
  static bool hasSymbol(String value) => _symbol.hasMatch(value);

  static bool isValid(String value) =>
      hasMinLength(value) &&
      hasLowercase(value) &&
      hasUppercase(value) &&
      hasDigit(value) &&
      hasSymbol(value);

  /// 0..1, for the strength meter.
  static double strength(String value) {
    if (value.isEmpty) return 0;
    final met = [
      hasMinLength(value),
      hasLowercase(value),
      hasUppercase(value),
      hasDigit(value),
      hasSymbol(value),
    ].where((ok) => ok).length;
    final bonus = value.length >= 12 ? 1 : 0;
    return ((met + bonus) / 6).clamp(0.0, 1.0);
  }
}
