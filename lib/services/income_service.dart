import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/income_source.dart';

class IncomeService {
  final _client = SupabaseConfig.client;
  static const _table = 'income_sources';
  final _uuid = const Uuid();

  String get _userId => _client.auth.currentUser!.id;

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
    // Get next sort order if not provided
    if (sortOrder == null) {
      final existing = await getIncomeSourcesForMonth(monthId);
      sortOrder = existing.isEmpty
          ? 0
          : existing.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
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
    if (name != null) updates['name'] = name;
    if (projected != null) updates['projected'] = projected;
    if (actual != null) updates['actual'] = actual;
    if (isRecurring != null) updates['is_recurring'] = isRecurring;
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    if (notes != null) updates['notes'] = notes;

    if (updates.isEmpty) {
      final current = await getIncomeSourceById(incomeSourceId);
      if (current == null) throw Exception('Income source not found');
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
}
