import '../config/supabase_config.dart';
import '../models/bug_report.dart';
import '../utils/errors/app_error.dart';
import '../utils/errors/error_mapper.dart';

class BugReportService {
  final _client = SupabaseConfig.client;
  static const _table = 'bug_reports';

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppError.unauthenticated();
    }
    return userId;
  }

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
    try {
      final response = await _client
          .from(_table)
          .insert(<String, dynamic>{
            'user_id': _userId,
            'title': title.trim(),
            'description': description.trim(),
            'category': bugReportCategoryToString(category),
            'severity': bugReportSeverityToString(severity),
            'app_version': appVersion,
            'platform': platform,
            'os_version': osVersion,
            'device_model': deviceModel,
            'error_stack_trace': errorStackTrace,
          })
          .select()
          .single();

      return BugReport.fromJson(response);
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppError(error, stackTrace: stackTrace);
    }
  }

  Future<List<BugReport>> getUserBugReports() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BugReport.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      throw ErrorMapper.toAppError(error, stackTrace: stackTrace);
    }
  }
}
