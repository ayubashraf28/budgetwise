import 'dart:io';

import 'package:budgetwise/utils/errors/app_error.dart';
import 'package:budgetwise/utils/errors/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns original AppError without remapping', () {
    const source = AppError.validation(technicalMessage: 'Invalid amount');
    final mapped = ErrorMapper.toAppError(source);

    expect(mapped, same(source));
    expect(mapped.code, AppErrorCode.validation);
  });

  test('maps socket exceptions to network errors', () {
    final mapped = ErrorMapper.toAppError(const SocketException('No route'));

    expect(mapped.code, AppErrorCode.network);
    expect(mapped.userMessage, contains('Network'));
  });

  test('maps not found strings to notFound', () {
    final mapped = ErrorMapper.toAppError(Exception('Transaction not found'));

    expect(mapped.code, AppErrorCode.notFound);
  });
}
