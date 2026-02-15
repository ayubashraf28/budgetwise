import 'package:flutter/foundation.dart';

enum BugReportCategory {
  bug,
  uiUx,
  performance,
  dataSync,
  crash,
  feedback,
  other,
}

enum BugReportSeverity {
  low,
  medium,
  high,
  critical,
}

enum BugReportStatus {
  open,
  inProgress,
  resolved,
  closed,
}

@immutable
class BugReport {
  final String id;
  final String userId;
  final String title;
  final String description;
  final BugReportCategory category;
  final BugReportSeverity severity;
  final String appVersion;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String? errorStackTrace;
  final BugReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BugReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    this.errorStackTrace,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: _bugReportCategoryFromString(json['category'] as String?),
      severity: _bugReportSeverityFromString(json['severity'] as String?),
      appVersion: json['app_version'] as String? ?? 'unknown',
      platform: json['platform'] as String? ?? 'unknown',
      osVersion: json['os_version'] as String? ?? 'unknown',
      deviceModel: json['device_model'] as String? ?? 'unknown',
      errorStackTrace: json['error_stack_trace'] as String?,
      status: _bugReportStatusFromString(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': bugReportCategoryToString(category),
      'severity': bugReportSeverityToString(severity),
      'app_version': appVersion,
      'platform': platform,
      'os_version': osVersion,
      'device_model': deviceModel,
      'error_stack_trace': errorStackTrace,
      'status': bugReportStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

String bugReportCategoryToString(BugReportCategory category) {
  switch (category) {
    case BugReportCategory.bug:
      return 'bug';
    case BugReportCategory.uiUx:
      return 'ui_ux';
    case BugReportCategory.performance:
      return 'performance';
    case BugReportCategory.dataSync:
      return 'data_sync';
    case BugReportCategory.crash:
      return 'crash';
    case BugReportCategory.feedback:
      return 'feedback';
    case BugReportCategory.other:
      return 'other';
  }
}

String bugReportSeverityToString(BugReportSeverity severity) {
  switch (severity) {
    case BugReportSeverity.low:
      return 'low';
    case BugReportSeverity.medium:
      return 'medium';
    case BugReportSeverity.high:
      return 'high';
    case BugReportSeverity.critical:
      return 'critical';
  }
}

String bugReportStatusToString(BugReportStatus status) {
  switch (status) {
    case BugReportStatus.open:
      return 'open';
    case BugReportStatus.inProgress:
      return 'in_progress';
    case BugReportStatus.resolved:
      return 'resolved';
    case BugReportStatus.closed:
      return 'closed';
  }
}

BugReportCategory _bugReportCategoryFromString(String? value) {
  switch (value) {
    case 'bug':
      return BugReportCategory.bug;
    case 'ui_ux':
      return BugReportCategory.uiUx;
    case 'performance':
      return BugReportCategory.performance;
    case 'data_sync':
      return BugReportCategory.dataSync;
    case 'crash':
      return BugReportCategory.crash;
    case 'feedback':
      return BugReportCategory.feedback;
    case 'other':
      return BugReportCategory.other;
    default:
      return BugReportCategory.bug;
  }
}

BugReportSeverity _bugReportSeverityFromString(String? value) {
  switch (value) {
    case 'low':
      return BugReportSeverity.low;
    case 'high':
      return BugReportSeverity.high;
    case 'critical':
      return BugReportSeverity.critical;
    case 'medium':
    default:
      return BugReportSeverity.medium;
  }
}

BugReportStatus _bugReportStatusFromString(String? value) {
  switch (value) {
    case 'in_progress':
      return BugReportStatus.inProgress;
    case 'resolved':
      return BugReportStatus.resolved;
    case 'closed':
      return BugReportStatus.closed;
    case 'open':
    default:
      return BugReportStatus.open;
  }
}
