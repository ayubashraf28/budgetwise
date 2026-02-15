class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static bool isValid(String? value) {
    return validate(value) == null;
  }
}

class PasswordValidator {
  static const int minLength = 8;
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'\d');
  static final RegExp _symbolRegex = RegExp(r'[^A-Za-z0-9]');

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (_characterClassScore(value) < 3) {
      return 'Use at least 3: uppercase, lowercase, number, symbol';
    }
    return null;
  }

  static String? validateForSignIn(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final error = validate(value);
    if (error != null) return error;

    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static bool isValid(String? value) {
    return validate(value) == null;
  }

  static PasswordStrength strength(String value) {
    if (value.isEmpty) return PasswordStrength.weak;

    var score = _characterClassScore(value);
    if (value.length >= 12) {
      score += 2;
    } else if (value.length >= 10) {
      score += 1;
    }

    if (score <= 3) return PasswordStrength.weak;
    if (score <= 5) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  static int _characterClassScore(String value) {
    var score = 0;
    if (_uppercaseRegex.hasMatch(value)) score++;
    if (_lowercaseRegex.hasMatch(value)) score++;
    if (_numberRegex.hasMatch(value)) score++;
    if (_symbolRegex.hasMatch(value)) score++;
    return score;
  }
}

class NameValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 80) {
      return 'Name must be at most 80 characters';
    }
    return null;
  }

  static bool isValid(String? value) {
    return validate(value) == null;
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}
