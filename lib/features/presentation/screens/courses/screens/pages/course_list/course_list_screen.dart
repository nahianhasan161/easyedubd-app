import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/course_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/widgets/course_card.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseRepository _repository = CourseRepository(
    Supabase.instance.client,
  );

  late Future<List<Course>> _coursesFuture;

  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    _coursesFuture = _repository.getCourses();
  }

  Future<void> _refreshCourses() async {
    final now = DateTime.now();

    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _refreshCooldown) {
      final remaining =
          _refreshCooldown.inSeconds -
          now.difference(_lastRefreshTime!).inSeconds;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please wait $remaining second${remaining == 1 ? '' : 's'} before refreshing again.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return;
    }

    _lastRefreshTime = now;

    setState(() {
      _loadCourses();
    });

    await _coursesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refreshCourses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  ),
                ],
              ),
            );
          }

          // Empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshCourses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(child: Text('No courses available.')),
                  ),
                ],
              ),
            );
          }

          final courses = snapshot.data!;

          // Success
          return RefreshIndicator(
            onRefresh: _refreshCourses,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];

                return CourseCard(
                  course: course,
                  onTap: () {
                    context.push('/course/${course.id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
