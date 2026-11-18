import 'dart:async';

import 'package:easyedubd_app/core/cache/cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-user lesson completion, backed by `public.lesson_progress`
/// (see supabase/migrations/0009_lesson_progress.sql).
class LessonProgressRepository {
  LessonProgressRepository(this._supabase);

  final SupabaseClient _supabase;

  static String _cacheKey(String userId) => 'progress_$userId';

  /// Ids of lessons the current user has completed. Falls back to the
  /// locally cached set when the network call fails (offline).
  Future<Set<String>> getCompletedLessonIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};
    final key = _cacheKey(user.id);

    try {
      final rows = await _supabase
          .from('lesson_progress')
          .select('lesson_id')
          .eq('profile_id', user.id)
          .timeout(const Duration(seconds: 8));
      final ids = {for (final r in rows) r['lesson_id'].toString()};
      await CacheService.putEnrollment(key, ids.toList());
      return ids;
    } catch (_) {
      final cached = CacheService.getEnrollment(key);
      if (cached is List) return cached.map((e) => e.toString()).toSet();
      return {};
    }
  }

  Future<void> setCompleted(String lessonId, {required bool completed}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('Not signed in');

    final query = completed
        ? _supabase.from('lesson_progress').upsert({
            'profile_id': user.id,
            'lesson_id': lessonId,
          })
        : _supabase
            .from('lesson_progress')
            .delete()
            .eq('profile_id', user.id)
            .eq('lesson_id', lessonId);
    await query.timeout(const Duration(seconds: 5));
  }
}

final lessonProgressRepositoryProvider = Provider<LessonProgressRepository>(
  (ref) => LessonProgressRepository(Supabase.instance.client),
);

/// Lesson ids the signed-in user has completed. Never errors.
final completedLessonIdsProvider = FutureProvider<Set<String>>((ref) async {
  try {
    return await ref
        .read(lessonProgressRepositoryProvider)
        .getCompletedLessonIds();
  } catch (_) {
    return <String>{};
  }
});
