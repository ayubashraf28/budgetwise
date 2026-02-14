import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/month.dart';
import '../utils/errors/app_error.dart';

class MonthService {
  final _client = SupabaseConfig.client;
  static const _table = 'months';
  final _uuid = const Uuid();

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppError.unauthenticated();
    }
    return userId;
  }

  /// Get all months for the current user
  Future<List<Month>> getAllMonths() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: false);

    return (response as List).map((e) => Month.fromJson(e)).toList();
  }

  /// Get the active month for the current user
  Future<Month?> getActiveMonth() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Month.fromJson(response);
  }

  /// Get a month by ID
  Future<Month?> getMonthById(String monthId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', monthId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Month.fromJson(response);
  }

  /// Get month by date (finds month containing the given date)
  Future<Month?> getMonthByDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .lte('start_date', dateStr)
        .gte('end_date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return Month.fromJson(response);
  }

  /// Create a new month
  Future<Month> createMonth({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = true,
    String? notes,
  }) async {
    // If this month is active, deactivate all other months
    if (isActive) {
      await _client
          .from(_table)
          .update({'is_active': false}).eq('user_id', _userId);
    }

    final now = DateTime.now();
    final month = Month(
      id: _uuid.v4(),
      userId: _userId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final response =
        await _client.from(_table).insert(month.toJson()).select().single();

    return Month.fromJson(response);
  }

  /// Create a month for the current calendar month
  Future<Month> createCurrentMonth() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0); // Last day of month

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return createMonth(
      name: '${monthNames[now.month - 1]} ${now.year}',
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );
  }

  /// Update a month
  Future<Month> updateMonth({
    required String monthId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (startDate != null) {
      updates['start_date'] =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }
    if (endDate != null) {
      updates['end_date'] =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }
    if (notes != null) updates['notes'] = notes;

    // Handle active status change
    if (isActive == true) {
      // Deactivate all other months first
      await _client
          .from(_table)
          .update({'is_active': false}).eq('user_id', _userId);
      updates['is_active'] = true;
    } else if (isActive == false) {
      updates['is_active'] = false;
    }

    if (updates.isEmpty) {
      final current = await getMonthById(monthId);
      if (current == null) {
        throw const AppError.notFound(
          technicalMessage: 'Month not found',
        );
      }
      return current;
    }

    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', monthId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Month.fromJson(response);
  }

  /// Set a month as active
  Future<Month> setActiveMonth(String monthId) async {
    return updateMonth(monthId: monthId, isActive: true);
  }

  /// Delete a month
  Future<void> deleteMonth(String monthId) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', monthId)
        .eq('user_id', _userId);
  }

  /// Get or create the current month
  Future<Month> getOrCreateCurrentMonth() async {
    final active = await getActiveMonth();
    if (active != null) return active;

    // Check if current calendar month exists
    final now = DateTime.now();
    final existing = await getMonthByDate(now);
    if (existing != null) {
      return setActiveMonth(existing.id);
    }

    // Create new month
    return createCurrentMonth();
  }

  /// Ensure all 12 months exist for the given year.
  /// Creates any missing months. Sets current calendar month as active.
  /// Returns all 12 months sorted chronologically.
  Future<List<Month>> ensureYearMonths(int year) async {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final now = DateTime.now();
    final currentMonthIndex = (now.year == year) ? now.month : -1;

    for (int m = 1; m <= 12; m++) {
      final startDate = DateTime(year, m, 1);
      final existing = await getMonthByDate(startDate);
      if (existing == null) {
        final endDate = DateTime(year, m + 1, 0); // Last day of month
        await createMonth(
          name: '${monthNames[m - 1]} $year',
          startDate: startDate,
          endDate: endDate,
          isActive: m == currentMonthIndex,
        );
      } else if (m == currentMonthIndex && !existing.isActive) {
        // Ensure current calendar month is active
        await setActiveMonth(existing.id);
      }
    }

    // Return all months for this year, sorted chronologically
    final allMonths = await getAllMonths();
    final yearMonths = allMonths.where((m) => m.startDate.year == year).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return yearMonths;
  }

  /// Get the month record for a given date. Creates it if it doesn't exist.
  Future<Month> getMonthForDate(DateTime date) async {
    final existing = await getMonthByDate(date);
    if (existing != null) return existing;

    // Create the month
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final startDate = DateTime(date.year, date.month, 1);
    final endDate = DateTime(date.year, date.month + 1, 0);

    return createMonth(
      name: '${monthNames[date.month - 1]} ${date.year}',
      startDate: startDate,
      endDate: endDate,
      isActive: false, // Don't change active month
    );
  }
}
