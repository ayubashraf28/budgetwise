import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../models/bug_report.dart';
import '../../providers/providers.dart';
import '../../utils/errors/error_mapper.dart';

class BugReportFormSheet extends ConsumerStatefulWidget {
  final BugReportCategory initialCategory;
  final bool feedbackMode;

  const BugReportFormSheet({
    super.key,
    this.initialCategory = BugReportCategory.bug,
    this.feedbackMode = false,
  });

  @override
  ConsumerState<BugReportFormSheet> createState() => _BugReportFormSheetState();
}

class _BugReportFormSheetState extends ConsumerState<BugReportFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stackTraceController = TextEditingController();

  late BugReportCategory _category;
  BugReportSeverity _severity = BugReportSeverity.medium;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    if (widget.feedbackMode) {
      _severity = BugReportSeverity.low;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stackTraceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = NeoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.stroke,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.feedbackMode
                              ? 'Send Feedback'
                              : 'Report a Bug',
                          style: AppTypography.h3.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _titleController,
                    label: widget.feedbackMode ? 'Subject' : 'Title',
                    maxLength: 120,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _descriptionController,
                    label: widget.feedbackMode
                        ? 'What would you like to share?'
                        : 'What happened?',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<BugReportCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: BugReportCategory.values
                        .map(
                          (category) => DropdownMenuItem<BugReportCategory>(
                            value: category,
                            child: Text(_categoryLabel(category)),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _category = value);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<BugReportSeverity>(
                    initialValue: _severity,
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                    ),
                    items: BugReportSeverity.values
                        .map(
                          (severity) => DropdownMenuItem<BugReportSeverity>(
                            value: severity,
                            child: Text(_severityLabel(severity)),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _severity = value);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _stackTraceController,
                    label: 'Stack trace (optional)',
                    maxLines: 3,
                    isRequired: false,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.feedbackMode ? 'Send' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    int? maxLength,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: (value) {
        if (!isRequired) return null;
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(bugReportNotifierProvider.notifier).submitBugReport(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            severity: _severity,
            errorStackTrace: _stackTraceController.text.trim().isEmpty
                ? null
                : _stackTraceController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.feedbackMode
                ? 'Feedback sent successfully'
                : 'Bug report submitted successfully',
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.toUserMessage(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Unable to submit right now.',
            ),
          ),
          backgroundColor: NeoTheme.negativeValue(context),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _categoryLabel(BugReportCategory category) {
    switch (category) {
      case BugReportCategory.bug:
        return 'Bug';
      case BugReportCategory.uiUx:
        return 'UI/UX';
      case BugReportCategory.performance:
        return 'Performance';
      case BugReportCategory.dataSync:
        return 'Data Sync';
      case BugReportCategory.crash:
        return 'Crash';
      case BugReportCategory.feedback:
        return 'Feedback';
      case BugReportCategory.other:
        return 'Other';
    }
  }

  String _severityLabel(BugReportSeverity severity) {
    switch (severity) {
      case BugReportSeverity.low:
        return 'Low';
      case BugReportSeverity.medium:
        return 'Medium';
      case BugReportSeverity.high:
        return 'High';
      case BugReportSeverity.critical:
        return 'Critical';
    }
  }
}
