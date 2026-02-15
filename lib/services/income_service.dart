import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/income_source.dart';
import '../models/month.dart';
import '../utils/errors/app_error.dart';
import '../utils/validators/input_validator.dart';

class IncomeService {
  final _client = SupabaseConfig.client;
  static const _table = 'income_sources';
  final _uuid = const Uuid();

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppError.unauthenticated();
    }
    return userId;
  }

  /// Get all income sources for a month
  Future<List<IncomeSource>> getIncomeSourcesForMonth(String monthId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('month_id', monthId)
        .order('sort_order', ascending: true);

    return (response as List).map((e) => IncomeSource.fromJson(e)).toList();
  }

  /// Get a single income source by ID
  Future<IncomeSource?> getIncomeSourceById(String incomeSourceId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', incomeSourceId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return IncomeSource.fromJson(response);
  }

  /// Create a new income source
  Future<IncomeSource> createIncomeSource({
    required String monthId,
    required String name,
    double projected = 0,
    bool isRecurring = false,
    int? sortOrder,
    String? notes,
  }) async {
    final nameError = InputValidator.validateBoundedName(
      name,
      fieldName: 'Income source name',
      maxLength: InputValidator.maxIncomeSourceNameLength,
    );
    if (nameError != null) {
      throw AppError.validation(technicalMessage: nameError);
    }
    final projectedError =
        InputValidator.validateNonNegativeAmountValue(projected);
    if (projectedError != null) {
      throw AppError.validation(technicalMessage: projectedError);
    }
    final notesError = InputValidator.validateNoteLength(
      notes,
      fieldName: 'Notes',
      maxLength: InputValidator.maxFormNoteLength,
    );
    if (notesError != null) {
      throw AppError.validation(technicalMessage: notesError);
    }

    // Get next sort order if not provided
    if (sortOrder == null) {
      final existing = await getIncomeSourcesForMonth(monthId);
      sortOrder = existing.isEmpty
          ? 0
          : existing.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) +
              1;
    }

    final now = DateTime.now();
    final incomeSource = IncomeSource(
      id: _uuid.v4(),
      userId: _userId,
      monthId: monthId,
      name: name,
      projected: projected,
      isRecurring: isRecurring,
      sortOrder: sortOrder,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _client
        .from(_table)
        .insert(incomeSource.toJson())
        .select()
        .single();

    return IncomeSource.fromJson(response);
  }

  /// Update an income source
  Future<IncomeSource> updateIncomeSource({
    required String incomeSourceId,
    String? name,
    double? projected,
    double? actual,
    bool? isRecurring,
    int? sortOrder,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      final nameError = InputValidator.validateBoundedName(
        name,
        fieldName: 'Income source name',
        maxLength: InputValidator.maxIncomeSourceNameLength,
      );
      if (nameError != null) {
        throw AppError.validation(technicalMessage: nameError);
      }
      updates['name'] = name;
    }
    if (projected != null) {
      final projectedError =
          InputValidator.validateNonNegativeAmountValue(projected);
      if (projectedError != null) {
        throw AppError.validation(technicalMessage: projectedError);
      }
      updates['projected'] = projected;
    }
    if (actual != null) {
      final actualError = InputValidator.validateNonNegativeAmountValue(actual);
      if (actualError != null) {
        throw AppError.validation(technicalMessage: actualError);
      }
      updates['actual'] = actual;
    }
    if (isRecurring != null) updates['is_recurring'] = isRecurring;
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    if (notes != null) {
      final notesError = InputValidator.validateNoteLength(
        notes,
        fieldName: 'Notes',
        maxLength: InputValidator.maxFormNoteLength,
      );
      if (notesError != null) {
        throw AppError.validation(technicalMessage: notesError);
      }
      updates['notes'] = notes;
    }

    if (updates.isEmpty) {
      final current = await getIncomeSourceById(incomeSourceId);
      if (current == null) {
        throw const AppError.notFound(
          technicalMessage: 'Income source not found',
        );
      }
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', incomeSourceId)
        .eq('user_id', _userId)
        .select()
        .single();

    return IncomeSource.fromJson(response);
  }

  /// Delete an income source
  Future<void> deleteIncomeSource(String incomeSourceId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', incomeSourceId)
        .eq('user_id', _userId);
  }

  /// Reorder income sources
  Future<void> reorderIncomeSources(List<String> incomeSourceIds) async {
    for (int i = 0; i < incomeSourceIds.length; i++) {
      await _client
          .from(_table)
          .update({'sort_order': i})
          .eq('id', incomeSourceIds[i])
          .eq('user_id', _userId);
    }
  }

  /// Get total projected income for a month
  Future<double> getTotalProjectedIncome(String monthId) async {
    final sources = await getIncomeSourcesForMonth(monthId);
    return sources.fold<double>(0.0, (sum, s) => sum + s.projected);
  }

  /// Get total actual income for a month
  Future<double> getTotalActualIncome(String monthId) async {
    final sources = await getIncomeSourcesForMonth(monthId);
    return sources.fold<double>(0.0, (sum, s) => sum + s.actual);
  }

  /// Copy income sources from one month to another
  Future<List<IncomeSource>> copyIncomeSourcesFromMonth({
    required String sourceMonthId,
    required String targetMonthId,
    bool copyProjectedAmounts = true,
  }) async {
    final sourceSources = await getIncomeSourcesForMonth(sourceMonthId);
    final newSources = <IncomeSource>[];

    for (final source in sourceSources) {
      final newSource = await createIncomeSource(
        monthId: targetMonthId,
        name: source.name,
        projected: copyProjectedAmounts ? source.projected : 0,
        isRecurring: source.isRecurring,
        sortOrder: source.sortOrder,
        notes: source.notes,
      );
      newSources.add(newSource);
    }

    return newSources;
  }

  /// Ensure a month has income sources. If empty, copy from the most recent
  /// month that has income sources (with projected amounts for recurring).
  Future<List<IncomeSource>> ensureIncomeSourcesForMonth(String monthId) async {
    final existing = await getIncomeSourcesForMonth(monthId);
    if (existing.isNotEmpty) return existing;

    // Find the most recent month that has income sources
    final allMonths = await _client
        .from('months')
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: false);

    for (final monthJson in allMonths) {
      final otherMonthId = monthJson['id'] as String;
      if (otherMonthId == monthId) continue;

      final otherSources = await getIncomeSourcesForMonth(otherMonthId);
      if (otherSources.isNotEmpty) {
        return copyIncomeSourcesFromMonth(
          sourceMonthId: otherMonthId,
          targetMonthId: monthId,
          copyProjectedAmounts: true,
        );
      }
    }

    // No months have income sources — return empty
    return [];
  }

  /// Sync a newly created income source to all other months in the year.
  /// Creates the income source in each month that doesn't already have
  /// an income source with the same name.
  Future<void> syncIncomeSourceToAllMonths({
    required IncomeSource incomeSource,
    required List<Month> allYearMonths,
  }) async {
    for (final month in allYearMonths) {
      if (month.id == incomeSource.monthId) continue;

      // Check if this month already has an income source with the same name
      final existing = await getIncomeSourcesForMonth(month.id);
      final alreadyExists = existing.any(
        (s) => s.name.toLowerCase() == incomeSource.name.toLowerCase(),
      );

      if (!alreadyExists) {
        await createIncomeSource(
          monthId: month.id,
          name: incomeSource.name,
          projected: incomeSource.isRecurring ? incomeSource.projected : 0,
          isRecurring: incomeSource.isRecurring,
          sortOrder: incomeSource.sortOrder,
          notes: incomeSource.notes,
        );
      }
    }
  }
}
