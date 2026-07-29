import 'dart:developer' as developer;

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveInit {
  static const String profileBox = 'profileBox';
  static const String courseBox = 'courseBox';
  static const String enrollmentBox = 'enrollmentBox';
  static const String enrolledCourseCacheBox = 'enrolledCourseCacheBox';

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);

      await Hive.openBox(profileBox);
      await Hive.openBox(courseBox);
      await Hive.openBox(enrollmentBox);
      await Hive.openBox(enrolledCourseCacheBox);

      developer.log('Hive initialized at ${dir.path}');
    } catch (e, st) {
      developer.log('Hive init failed', error: e, stackTrace: st);
    }
  }

  static Future<void> clearAll() async {
    await Hive.box(profileBox).clear();
    await Hive.box(courseBox).clear();
    await Hive.box(enrollmentBox).clear();
    await Hive.box(enrolledCourseCacheBox).clear();
  }
}
