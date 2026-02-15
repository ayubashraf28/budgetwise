import 'package:budgetwise/models/bug_report.dart';
import 'package:budgetwise/providers/auth_provider.dart';
import 'package:budgetwise/providers/bug_report_provider.dart';
import 'package:budgetwise/services/bug_report_service.dart';
import 'package:budgetwise/utils/errors/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.c2lnbmF0dXJl',
      );
    } catch (_) {
      // Already initialized in this test process.
    }
  });

  test('submitBugReport creates and returns report', () async {
    final fakeService = _FakeBugReportService();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        bugReportServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(bugReportNotifierProvider.notifier);
    final report = await notifier.submitBugReport(
      title: 'Crash on save',
      description: 'App crashes while saving',
      category: BugReportCategory.crash,
      severity: BugReportSeverity.high,
    );

    expect(report.title, 'Crash on save');
    expect(fakeService.createCalls, 1);
  });

  test('submitBugReport propagates mapped errors', () async {
    final fakeService = _FakeBugReportService()
      ..createError = const AppError.validation(
        technicalMessage: 'invalid payload',
      );
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => _fakeUser()),
        bugReportServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(bugReportNotifierProvider.notifier);
    await expectLater(
      () => notifier.submitBugReport(
        title: 'A',
        description: 'B',
        category: BugReportCategory.other,
        severity: BugReportSeverity.low,
      ),
      throwsA(isA<AppError>()),
    );
  });
}

User _fakeUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'user@example.com',
    'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  })!;
}

class _FakeBugReportService extends BugReportService {
  int createCalls = 0;
  Object? createError;

  @override
  Future<List<BugReport>> getUserBugReports() async {
    return const <BugReport>[];
  }

  @override
  Future<BugReport> createBugReport({
    required String title,
    required String description,
    required BugReportCategory category,
    required BugReportSeverity severity,
    required String appVersion,
    required String platform,
    required String osVersion,
    required String deviceModel,
    String? errorStackTrace,
  }) async {
    if (createError != null) throw createError!;
    createCalls += 1;
    final now = DateTime.utc(2026, 1, 1);
    return BugReport(
      id: 'bug-1',
      userId: 'user-1',
      title: title,
      description: description,
      category: category,
      severity: severity,
      appVersion: appVersion,
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
      errorStackTrace: errorStackTrace,
      status: BugReportStatus.open,
      createdAt: now,
      updatedAt: now,
    );
  }
}
