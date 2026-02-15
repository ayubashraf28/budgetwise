part of 'transaction_form_sheet.dart';

extension _TransactionFormSheetCalculator on _TransactionFormSheetState {
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _handleDigit(String digit) {
    _dismissKeyboard();
    final decimalPlaces =
        InputValidator.decimalPlacesForCurrency(ref.read(currencyProvider));

    _updateState(() {
      if (_shouldResetDisplay) {
        if (digit == '.' && decimalPlaces == 0) {
          _showError('This currency requires whole numbers only');
          return;
        }
        _displayValue = digit == '.' ? '0.' : digit;
        _shouldResetDisplay = false;
        return;
      }

      if (digit == '.') {
        if (decimalPlaces == 0) {
          _showError('This currency requires whole numbers only');
          return;
        }
        if (_displayValue.contains('.')) return;
        if (_displayValue.length >= 12) return;
        _displayValue = '$_displayValue.';
        return;
      }

      if (_displayValue.contains('.')) {
        final decimalDigits = _displayValue.split('.').last.length;
        if (decimalDigits >= decimalPlaces) return;
      }

      if (_displayValue == '0') {
        _displayValue = digit;
        return;
      }

      if (_displayValue.length >= 12) return;
      _displayValue = '$_displayValue$digit';
    });
  }

  void _handleOperator(String operator) {
    _dismissKeyboard();

    final currentValue = double.tryParse(_displayValue) ?? 0;
    _updateState(() {
      if (_pendingOperator == null) {
        _runningTotal = currentValue;
      } else if (!_shouldResetDisplay) {
        _applyPendingOperation(currentValue);
      }

      _pendingOperator = operator;
      _displayValue = _formatDisplayNumber(_runningTotal);
      _shouldResetDisplay = true;
    });
  }

  void _handleEquals() {
    _dismissKeyboard();
    if (_pendingOperator == null) return;

    _updateState(() {
      final operand = _shouldResetDisplay
          ? _runningTotal
          : double.tryParse(_displayValue) ?? 0;
      _applyPendingOperation(operand);
      _pendingOperator = null;
      _displayValue = _formatDisplayNumber(_runningTotal);
      _shouldResetDisplay = true;
    });
  }

  void _handleBackspace() {
    _dismissKeyboard();

    _updateState(() {
      if (_shouldResetDisplay) {
        _displayValue = '0';
        _shouldResetDisplay = false;
        return;
      }

      if (_displayValue.length <= 1) {
        _displayValue = '0';
        return;
      }

      _displayValue = _displayValue.substring(0, _displayValue.length - 1);
    });
  }

  void _applyPendingOperation(double operand) {
    switch (_pendingOperator) {
      case '+':
        _runningTotal += operand;
      case '-':
        _runningTotal -= operand;
      case '\u00D7':
        _runningTotal *= operand;
      case '\u00F7':
        if (operand == 0) {
          _showError('Cannot divide by zero');
          return;
        }
        _runningTotal /= operand;
    }

    if (_runningTotal.abs() < 0.0000001) {
      _runningTotal = 0;
    } else {
      _runningTotal = double.parse(_runningTotal.toStringAsFixed(6));
    }
  }

  double _resolveAmountForSubmit() {
    if (_pendingOperator != null) {
      return _runningTotal;
    }
    return double.tryParse(_displayValue) ?? 0;
  }

  String _formatDisplayNumber(double value) {
    if (value.isNaN || value.isInfinite) return '0';

    var formatted = value.toStringAsFixed(6);
    formatted = formatted.replaceFirst(RegExp(r'\.?0+$'), '');
    if (formatted.isEmpty || formatted == '-0') {
      formatted = '0';
    }

    if (formatted.length > 12) {
      formatted = value.toStringAsPrecision(8);
      if (formatted.contains('e') || formatted.contains('E')) {
        formatted = value.toStringAsFixed(2);
      }
      if (formatted.length > 12) {
        formatted = formatted.substring(0, 12);
      }
    }

    return formatted;
  }
}
