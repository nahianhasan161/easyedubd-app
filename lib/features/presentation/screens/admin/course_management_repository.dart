import 'package:easyedubd_app/features/presentation/screens/courses/models/chapter.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/lessons.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaginatedAdminCourses {
  final List<Course> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedAdminCourses({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
  int get start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get end => (start + items.length - 1).clamp(0, total);
}

class PaginatedAdminChapters {
  final List<Chapter> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedAdminChapters({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
  int get start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get end => (start + items.length - 1).clamp(0, total);
}

class PaginatedAdminLessons {
  final List<Lesson> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedAdminLessons({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
  int get start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get end => (start + items.length - 1).clamp(0, total);
}

class AdminCourseManagementRepository {
  final SupabaseClient _supabase;

  AdminCourseManagementRepository(this._supabase);

  // Courses
  Future<PaginatedAdminCourses> getCourses({
    required int page,
    int pageSize = 15,
    String? search,
  }) async {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;

    var query = _supabase.from('course').select();

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(start, end)
        .count(CountOption.exact);

    final data = response.data as List;
    final items = data
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedAdminCourses(
      items: items,
      total: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createCourse(Map<String, dynamic> data) async {
    await _supabase.from('course').insert(data);
  }

  Future<void> updateCourse(int id, Map<String, dynamic> data) async {
    await _supabase.from('course').update(data).eq('id', id);
  }

  Future<void> deleteCourse(int id) async {
    await _supabase.from('course').delete().eq('id', id);
  }

  // Chapters
  Future<PaginatedAdminChapters> getChapters({
    required int courseId,
    required int page,
    int pageSize = 15,
    String? search,
  }) async {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;

    var query = _supabase
        .from('chapter')
        .select()
        .eq('course_id', courseId);

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }

    final response = await query
        .order('position', ascending: true)
        .range(start, end)
        .count(CountOption.exact);

    final data = response.data as List;
    final items = data
        .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedAdminChapters(
      items: items,
      total: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createChapter(Map<String, dynamic> data) async {
    await _supabase.from('chapter').insert(data);
  }

  Future<void> updateChapter(int id, Map<String, dynamic> data) async {
    await _supabase.from('chapter').update(data).eq('id', id);
  }

  Future<void> deleteChapter(int id) async {
    await _supabase.from('chapter').delete().eq('id', id);
  }

  // Lessons
  Future<PaginatedAdminLessons> getLessons({
    required int chapterId,
    required int page,
    int pageSize = 15,
    String? search,
  }) async {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;

    var query = _supabase
        .from('lesson')
        .select()
        .eq('chapter_id', chapterId);

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }

    final response = await query
        .order('position', ascending: true)
        .range(start, end)
        .count(CountOption.exact);

    final data = response.data as List;
    final items = data
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedAdminLessons(
      items: items,
      total: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createLesson(Map<String, dynamic> data) async {
    await _supabase.from('lesson').insert(data);
  }

  Future<void> updateLesson(int id, Map<String, dynamic> data) async {
    await _supabase.from('lesson').update(data).eq('id', id);
  }

  Future<void> deleteLesson(int id) async {
    await _supabase.from('lesson').delete().eq('id', id);
  }
}

final adminCourseManagementRepositoryProvider =
    Provider<AdminCourseManagementRepository>((ref) {
  return AdminCourseManagementRepository(ref.read(supabaseProvider));
});
