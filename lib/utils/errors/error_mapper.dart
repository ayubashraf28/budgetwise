import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppError toAppError(
    Object error, {
    StackTrace? stackTrace,
    String? fallbackTechnicalMessage,
  }) {
    if (error is AppError) return error;

    if (error is TimeoutException) {
      return AppError.timeout(
        technicalMessage: error.message ?? 'Operation timed out',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is SocketException) {
      return AppError.network(
        technicalMessage: error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is AuthException) {
      return _fromMessage(error.message, error, stackTrace);
    }

    if (error is PostgrestException) {
      if (error.code == '23505') {
        return AppError.conflict(
          technicalMessage: error.message,
          userMessage: 'This data already exists.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      return AppError.database(
        technicalMessage: error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return AppError.validation(
        technicalMessage: error.message,
        userMessage: 'The provided data format is invalid.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return _fromMessage(
      fallbackTechnicalMessage ?? error.toString(),
      error,
      stackTrace,
    );
  }

  static String toUserMessage(
    Object error, {
    StackTrace? stackTrace,
    String fallbackMessage = 'Something went wrong. Please try again.',
  }) {
    final appError = toAppError(error, stackTrace: stackTrace);
    if (appError.userMessage.trim().isEmpty) {
      return fallbackMessage;
    }
    return appError.userMessage;
  }

  static AppError _fromMessage(
    String rawMessage,
    Object error,
    StackTrace? stackTrace,
  ) {
    final message = rawMessage.toLowerCase();

    if (message.contains('not authenticated') ||
        message.contains('jwt') && message.contains('expired') ||
        message.contains('session')) {
      return AppError.unauthenticated(
        technicalMessage: rawMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('not found')) {
      return AppError.notFound(
        technicalMessage: rawMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('socket') ||
        message.contains('offline') ||
        message.contains('timed out')) {
      return AppError.network(
        technicalMessage: rawMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('already exists') ||
        message.contains('already linked') ||
        message.contains('duplicate')) {
      return AppError.conflict(
        technicalMessage: rawMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (message.contains('invalid') ||
        message.contains('missing') ||
        message.contains('required')) {
      return AppError.validation(
        technicalMessage: rawMessage,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppError.unknown(
      technicalMessage: rawMessage,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
