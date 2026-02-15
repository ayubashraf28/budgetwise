import 'package:budgetwise/utils/validators/email_validator.dart';
import 'package:budgetwise/utils/validators/input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidator amount validation', () {
    test('rejects fractional JPY amounts', () {
      final error = InputValidator.validateNonNegativeAmountInput(
        '100.50',
        currencyCode: 'JPY',
        fieldName: 'Amount',
      );

      expect(error, isNotNull);
      expect(error, contains('whole numbers'));
    });

    test('accepts 2-decimal USD amounts', () {
      final error = InputValidator.validateNonNegativeAmountInput(
        '100.50',
        currencyCode: 'USD',
        fieldName: 'Amount',
      );

      expect(error, isNull);
    });

    test('rejects transaction date beyond allowed future window', () {
      final now = DateTime(2026, 2, 15);
      final futureDate = now.add(const Duration(days: 45));

      final error = InputValidator.validateTransactionDate(
        futureDate,
        now: now,
      );

      expect(error, isNotNull);
      expect(error, contains('31 days'));
    });
  });

  group('PasswordValidator', () {
    test('requires 8 chars and complexity for registration', () {
      expect(PasswordValidator.validate('short7!'), isNotNull);
      expect(PasswordValidator.validate('alllowercase1'), isNotNull);
      expect(PasswordValidator.validate('StrongP@ss1'), isNull);
    });

    test('allows short passwords at sign-in validation layer', () {
      expect(PasswordValidator.validateForSignIn('a'), isNull);
      expect(PasswordValidator.validateForSignIn(''), isNotNull);
    });

    test('returns stronger score for complex password', () {
      final weak = PasswordValidator.strength('password');
      final strong = PasswordValidator.strength('Sup3r-Complex-P@ss!');

      expect(weak, PasswordStrength.weak);
      expect(strong, PasswordStrength.strong);
    });
  });
}
