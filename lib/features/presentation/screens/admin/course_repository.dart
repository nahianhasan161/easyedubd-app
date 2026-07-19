import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/enrollment.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaginatedCourses {
  final List<Course> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedCourses({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
  int get start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get end => (start + items.length - 1).clamp(0, total);
}

class PaginatedEnrollments {
  final List<_EnrollmentRow> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedEnrollments({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (total / pageSize).ceil();
  int get start => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get end => (start + items.length - 1).clamp(0, total);
}

class _EnrollmentRow {
  final int id;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? courseId;
  final int? bundleId;
  final String profileId;
  final String? courseTitle;
  final String? fullName;
  final String? email;
  final String? phone;

  _EnrollmentRow({
    required this.id,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.courseId,
    this.bundleId,
    required this.profileId,
    this.courseTitle,
    this.fullName,
    this.email,
    this.phone,
  });

  factory _EnrollmentRow.fromJson(Map<String, dynamic> json, [Profile? profile]) {
    final course = json['course'] as Map<String, dynamic>? ?? {};
    final profileJson = json['profiles'] as Map<String, dynamic>?;

    final embeddedPhone = profileJson?['phone'];
    final embeddedPhoneStr =
        embeddedPhone is String ? embeddedPhone : embeddedPhone?.toString();

    return _EnrollmentRow(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'active',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      courseId: json['course_id'] as int?,
      bundleId: json['bundle_id'] as int?,
      profileId: json['profile_id'] as String,
      courseTitle: course['title'] as String?,
      fullName: profileJson?['full_name'] as String? ?? profile?.fullName,
      email: profileJson?['email'] as String? ?? profile?.email,
      phone: embeddedPhoneStr ?? profile?.phone,
    );
  }
}

class AdminCourseRepository {
  final SupabaseClient _supabase;

  AdminCourseRepository(this._supabase);

  Future<PaginatedCourses> getCourses({
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

    return PaginatedCourses(
      items: items,
      total: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<PaginatedEnrollments> getEnrollments({
    required int page,
    int pageSize = 15,
    String? search,
    int? courseId,
    String? profileId,
  }) async {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;

    var query = _supabase
        .from('enrollments')
        .select(
            '*, course!left(title), profiles!enrollments_profile_id_fkey(id, full_name, email, phone)');

    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }

    if (profileId != null) {
      query = query.eq('profile_id', profileId);
    }

    Future<Map<String, Profile>> _fetchProfiles(List<Map<String, dynamic>> rows) async {
      // Name/email/phone come directly from the embedded `profiles` relation
      // in the enrollment query, so no extra lookup is needed.
      return {};
    }

    if (search != null && search.trim().isNotEmpty) {
      final term = search.trim().toLowerCase();
      final data = await query.order('created_at', ascending: false).range(0, 1000).count(CountOption.exact);

      final rawRows = (data.data as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final profiles = await _fetchProfiles(rawRows);

      final all = rawRows
          .map((e) => _EnrollmentRow.fromJson(e, profiles[e['profile_id'] as String]))
          .where((row) {
            final name = row.fullName?.toLowerCase() ?? '';
            final email = row.email?.toLowerCase() ?? '';
            final phone = row.phone?.toLowerCase() ?? '';
            return name.contains(term) ||
                email.contains(term) ||
                phone.contains(term);
          })
          .toList();

      return PaginatedEnrollments(
        items: all.take(pageSize).toList(),
        total: all.length,
        page: page,
        pageSize: pageSize,
      );
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(start, end)
        .count(CountOption.exact);

    final rawRows = (response.data as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final profiles = await _fetchProfiles(rawRows);

    final items = rawRows
        .map((e) => _EnrollmentRow.fromJson(e, profiles[e['profile_id'] as String]))
        .toList();

    return PaginatedEnrollments(
      items: items,
      total: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> enrollUser({
    required String profileId,
    required int courseId,
  }) async {
    await _supabase.from('enrollments').insert({
      'profile_id': profileId,
      'course_id': courseId,
      'status': 'active',
      'expires_at': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeEnrollment(int enrollmentId) async {
    await _supabase.from('enrollments').delete().eq('id', enrollmentId);
  }

  Future<List<Profile>> searchUsers(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return [];

    // All searchable fields now live on the `profiles` table, so we query it
    // directly (no RPC). `phone` is numeric, so match it exactly when the term
    // looks numeric; otherwise match name/email with ILIKE.
    final filters = [
      'full_name.ilike.%$trimmed%',
      'email.ilike.%$trimmed%',
    ];
    if (double.tryParse(trimmed) != null) {
      filters.add('phone.eq.$trimmed');
    }

    final response = await _supabase
        .from('profiles')
        .select()
        .or(filters.join(','))
        .order('full_name')
        .limit(20);

    final data = response as List;
    return data
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getEnrolledProfileIds(int courseId) async {
    final data = await _supabase
        .from('enrollments')
        .select('profile_id')
        .eq('course_id', courseId);
    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['profile_id'] as String)
        .toList();
  }
}

final adminCourseRepositoryProvider =
    Provider<AdminCourseRepository>((ref) {
  return AdminCourseRepository(ref.read(supabaseProvider));
});
