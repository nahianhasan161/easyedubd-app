import 'package:easyedubd_app/features/presentation/screens/courses/providers/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/screens/pages/course_list/repository/course_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/widgets/course_card.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  final bool enrolledOnly;

  const CourseListScreen({super.key, this.enrolledOnly = false});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  final CourseRepository _repository = CourseRepository(
    Supabase.instance.client,
  );

  late Future<List<Course>> _coursesFuture;

  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 5);

  String selectedYear = 'All';
  String selectedSubject = 'All';
  String selectedType = 'All';
  String selectedEnrollment = 'All';

  @override
  void initState() {
    super.initState();

    if (widget.enrolledOnly) {
      selectedEnrollment = 'Enrolled';
    }

    _loadCourses();
  }

  void _loadCourses() {
    _coursesFuture = _repository.getCourses();
  }

  List<Course> _filterCourses(
    List<Course> courses,

    Set<int> enrolledCourseIds,
  ) {
    return courses.where((course) {
      if (course.status == 'draft') return false;

      final yearMatch = selectedYear == 'All' || course.year == selectedYear;

      final subjectMatch =
          selectedSubject == 'All' ||
          course.subject.toLowerCase() == selectedSubject.toLowerCase();

      final typeMatch =
          selectedType == 'All' ||
          (selectedType == 'Free' && course.is_free) ||
          (selectedType == 'Paid' && !course.is_free);

      final enrolled = enrolledCourseIds.contains(course.id);

      if (widget.enrolledOnly && !enrolled) {
        return false;
      }

      return yearMatch && subjectMatch && typeMatch;
    }).toList();
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: (MediaQuery.of(context).size.width - 40) / 3,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: '1st', child: Text('1st')),
                DropdownMenuItem(value: '2nd', child: Text('2nd')),
                DropdownMenuItem(value: '3rd', child: Text('3rd')),
                DropdownMenuItem(value: '4th', child: Text('4th')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedYear = value!;
                });
              },
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: (MediaQuery.of(context).size.width - 40) / 3,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Math', child: Text('Math')),
                DropdownMenuItem(value: 'Physics', child: Text('Physics')),
                DropdownMenuItem(value: 'Chemistry', child: Text('Chemistry')),
                DropdownMenuItem(value: 'Biology', child: Text('Biology')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedSubject = value!;
                });
              },
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: (MediaQuery.of(context).size.width - 40) / 3,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Free', child: Text('Free')),
                DropdownMenuItem(value: 'Paid', child: Text('Paid')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
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
    final enrolledAsync = ref.watch(enrolledCourseIdsProvider);

    return Scaffold(
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No courses available.'));
          }

          return enrolledAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),

            error: (e, _) => Center(child: Text('Error: $e')),

            data: (enrolledCourseIds) {
              final courses = _filterCourses(snapshot.data!, enrolledCourseIds);

              return RefreshIndicator(
                onRefresh: _refreshCourses,
                child: Column(
                  children: [
                    if (!widget.enrolledOnly) _buildFilters(),
                    Expanded(
                      child: courses.isEmpty
                          ? const Center(child: Text('No courses found.'))
                          : ListView.builder(
                              itemCount: courses.length,
                              itemBuilder: (context, index) {
                                final course = courses[index];

                                final isEnrolled = enrolledCourseIds.contains(
                                  course.id,
                                );

                                return CourseCard(
                                  course: course,
                                  isEnrolled:
                                      isEnrolled ||
                                      course.is_free, // ✅ ADD THIS
                                  onTap: () {
                                    context.push('/course/${course.id}');
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
