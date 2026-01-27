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
  static const int minLength = 6;

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
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
}

class NameValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static bool isValid(String? value) {
    return validate(value) == null;
  }
}
