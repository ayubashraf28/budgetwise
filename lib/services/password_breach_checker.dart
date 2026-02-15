import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Checks passwords against the HaveIBeenPwned Passwords API using
/// k-anonymity (only the first 5 characters of the SHA-1 hash are sent).
/// The full password never leaves the device.
class PasswordBreachChecker {
  static const _apiBase = 'https://api.pwnedpasswords.com/range/';
  static const Duration _timeout = Duration(seconds: 5);

  /// Returns `true` if the password has appeared in known data breaches.
  /// Returns `false` if the password is safe **or** if the API is unreachable
  /// (fail-open: we don't block signup when HIBP is down).
  static Future<bool> isBreached(String password) async {
    try {
      final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);

      final response = await http
          .get(Uri.parse('$_apiBase$prefix'))
          .timeout(_timeout);

      if (response.statusCode != 200) return false;

      // Each line is "HASH_SUFFIX:COUNT"
      final lines = response.body.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.isNotEmpty && parts[0].trim() == suffix) {
          return true;
        }
      }
      return false;
    } catch (_) {
      // Network error, timeout, etc. — don't block the user.
      return false;
    }
  }
}
