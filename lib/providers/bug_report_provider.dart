import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bug_report.dart';
import '../services/bug_report_service.dart';
import '../utils/device_info_helper.dart';
import '../utils/errors/error_mapper.dart';
import 'auth_provider.dart';

final bugReportServiceProvider = Provider<BugReportService>((ref) {
  return BugReportService();
});

final userBugReportsProvider = FutureProvider<List<BugReport>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <BugReport>[];

  final service = ref.watch(bugReportServiceProvider);
  return service.getUserBugReports();
});

class BugReportNotifier extends AsyncNotifier<List<BugReport>> {
  @override
  Future<List<BugReport>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return <BugReport>[];
    final service = ref.watch(bugReportServiceProvider);
    return service.getUserBugReports();
  }

  Future<BugReport> submitBugReport({
    required String title,
    required String description,
    required BugReportCategory category,
    required BugReportSeverity severity,
    String? errorStackTrace,
  }) async {
    try {
      final deviceInfo = await DeviceInfoHelper.collect();
      final service = ref.read(bugReportServiceProvider);
      final report = await service.createBugReport(
        title: title,
        description: description,
        category: category,
        severity: severity,
        appVersion: deviceInfo.appVersion,
        platform: deviceInfo.platform,
        osVersion: deviceInfo.osVersion,
        deviceModel: deviceInfo.deviceModel,
        errorStackTrace: errorStackTrace,
      );

      ref.invalidateSelf();
      ref.invalidate(userBugReportsProvider);
      return report;
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppError(error, stackTrace: stackTrace);
    }
  }
}

final bugReportNotifierProvider =
    AsyncNotifierProvider<BugReportNotifier, List<BugReport>>(
  BugReportNotifier.new,
);
