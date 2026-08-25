import 'package:hive_flutter/hive_flutter.dart';

/// Local cache layer for course/enrollment data.
/// Caches persist across app restarts and enable offline browsing.
class CacheService {
  static const String _courseBoxName = 'course_cache';
  static const String _enrollmentBoxName = 'enrollment_cache';
  static const String _profileBoxName = 'profile_cache';
  static const String _metaBoxName = 'cache_meta';
  static const String _kLastInvalidated = 'last_invalidated_ms';
  static const String _kLastSeenCacheVersion = 'last_seen_cache_version';

  static late Box _courses;
  static late Box _enrollments;
  static late Box _profiles;
  static late Box _meta;
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _courses = await Hive.openBox(_courseBoxName);
    _enrollments = await Hive.openBox(_enrollmentBoxName);
    _profiles = await Hive.openBox(_profileBoxName);
    _meta = await Hive.openBox(_metaBoxName);
    _ready = true;
  }

  // ============ Course Cache ============
  static dynamic getCourse(String key) {
    if (!_ready) return null;
    return _courses.get(key);
  }

  static Future<void> putCourse(String key, dynamic data) async {
    if (!_ready) return;
    await _courses.put(key, data);
  }

  static Future<void> deleteCourse(String key) async {
    if (!_ready) return;
    await _courses.delete(key);
  }

  static String courseKey({
    int? courseId,
    String? year,
    String? subject,
    String? type,
    int? offset,
    int? limit,
    bool includeChapters = true,
  }) {
    if (courseId != null) return 'course_$courseId';
    return 'list_${year ?? 'all'}_${subject ?? 'all'}_${type ?? 'all'}_'
        '${offset ?? 0}_${limit ?? 0}_$includeChapters';
  }

  static Future<void> invalidateAllCourses() async {
    if (!_ready) return;
    await _courses.clear();
    await _courses.put(
      _kLastInvalidated,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ============ Enrollment Cache ============
  static dynamic getEnrollment(String key) {
    if (!_ready) return null;
    return _enrollments.get(key);
  }

  static Future<void> putEnrollment(String key, dynamic data) async {
    if (!_ready) return;
    await _enrollments.put(key, data);
  }

  static String enrollmentKey(String userId) => 'enrolled_$userId';

  static Future<void> invalidateAllEnrollments() async {
    if (!_ready) return;
    await _enrollments.clear();
    await _enrollments.put(
      _kLastInvalidated,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ============ Profile Cache ============
  static dynamic getProfile(String key) {
    if (!_ready) return null;
    return _profiles.get(key);
  }

  static Future<void> putProfile(String key, dynamic data) async {
    if (!_ready) return;
    await _profiles.put(key, data);
  }

  static String profileKey(String userId) => 'profile_$userId';

  static Future<void> invalidateProfile(String userId) async {
    if (!_ready) return;
    await _profiles.delete(profileKey(userId));
  }

  // ============ Version Tracking ============
  static int? getLastCourseInvalidated() {
    if (!_ready) return null;
    return _courses.get(_kLastInvalidated) as int?;
  }

  static int? getLastEnrollmentInvalidated() {
    if (!_ready) return null;
    return _enrollments.get(_kLastInvalidated) as int?;
  }

  // ============ Cache Version (polling) ============
  static int? getLastSeenCacheVersion() {
    if (!_ready) return null;
    return _meta.get(_kLastSeenCacheVersion) as int?;
  }

  static Future<void> setLastSeenCacheVersion(int version) async {
    if (!_ready) return;
    await _meta.put(_kLastSeenCacheVersion, version);
  }

  static Future<void> clearAll() async {
    if (!_ready) return;
    await _courses.clear();
    await _enrollments.clear();
    await _profiles.clear();
  }

  /// Recursively converts a Hive-deserialized value into one whose maps are
  /// all `Map<String, dynamic>`. Without this, values that were originally
  /// `Map<String, dynamic>` come back from Hive as `Map<dynamic, dynamic>`
  /// (because Hive stores map keys as `dynamic`), which breaks the
  /// `Map<String, dynamic>` casts in `*.fromJson(...)` and surfaces as
  /// "type 'Map<dynamic,dynamic>' is not a subtype of type 'Map<String,dynamic>'".
  static dynamic normalize(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((k, v) {
        result[k.toString()] = normalize(v);
      });
      return result;
    }
    if (value is List) {
      return value.map(normalize).toList();
    }
    return value;
  }
}
