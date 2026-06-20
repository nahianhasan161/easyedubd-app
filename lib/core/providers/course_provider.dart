import 'package:easyedubd_app/features/presentation/screens/courses/data/dummy_courses.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coursesProvider = Provider<List<Course>>((ref) {
  return dummyCourses;
});
