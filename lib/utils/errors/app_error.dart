import 'package:flutter/foundation.dart';

enum AppErrorCode {
  unauthenticated,
  unauthorized,
  notFound,
  validation,
  conflict,
  network,
  timeout,
  database,
  unknown,
}

@immutable
class AppError implements Exception {
  final AppErrorCode code;
  final String technicalMessage;
  final String userMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppError({
    required this.code,
    required this.technicalMessage,
    required this.userMessage,
    this.cause,
    this.stackTrace,
  });

  const AppError.unauthenticated({
    String technicalMessage = 'User not authenticated',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.unauthenticated,
          technicalMessage: technicalMessage,
          userMessage: 'Please sign in and try again.',
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.unauthorized({
    String technicalMessage = 'Operation not permitted',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.unauthorized,
          technicalMessage: technicalMessage,
          userMessage: 'You are not allowed to perform this action.',
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.notFound({
    String technicalMessage = 'Requested resource was not found',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.notFound,
          technicalMessage: technicalMessage,
          userMessage: 'The requested data could not be found.',
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.validation({
    required String technicalMessage,
    String userMessage = 'Please check your input and try again.',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.validation,
          technicalMessage: technicalMessage,
          userMessage: userMessage,
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.conflict({
    required String technicalMessage,
    String userMessage = 'This action conflicts with existing data.',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.conflict,
          technicalMessage: technicalMessage,
          userMessage: userMessage,
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.network({
    String technicalMessage = 'Network error',
    String userMessage = 'Network error. Please check your connection.',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.network,
          technicalMessage: technicalMessage,
          userMessage: userMessage,
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.timeout({
    String technicalMessage = 'Operation timed out',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.timeout,
          technicalMessage: technicalMessage,
          userMessage: 'Request timed out. Please try again.',
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.database({
    required String technicalMessage,
    String userMessage = 'Unable to process your data right now.',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.database,
          technicalMessage: technicalMessage,
          userMessage: userMessage,
          cause: cause,
          stackTrace: stackTrace,
        );

  const AppError.unknown({
    String technicalMessage = 'Unexpected error',
    String userMessage = 'Something went wrong. Please try again.',
    Object? cause,
    StackTrace? stackTrace,
  }) : this(
          code: AppErrorCode.unknown,
          technicalMessage: technicalMessage,
          userMessage: userMessage,
          cause: cause,
          stackTrace: stackTrace,
        );

  @override
  String toString() => technicalMessage;
}
