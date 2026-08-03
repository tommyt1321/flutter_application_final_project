import 'package:hive_ce/hive_ce.dart';

import '../models/analytics_summary.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._box);

  final Box<AnalyticsSummary> _box;

  /// Cached summaries belong to a single user; we key the box entry by
  /// userId so each user has exactly one cached summary at a time (the
  /// most recently generated one).
  AnalyticsSummary? getCachedSummary(String userId) {
    final summary = _box.get(userId);

    if (summary == null || summary.ownerUserId != userId) {
      return null;
    }

    return summary;
  }

  Future<void> saveSummary(AnalyticsSummary summary, {required String userId}) async {
    final savedSummary = summary.copyWith(ownerUserId: userId);
    await _box.put(userId, savedSummary);
  }

  Future<void> clearForUser(String userId) async {
    await _box.delete(userId);
  }
}
