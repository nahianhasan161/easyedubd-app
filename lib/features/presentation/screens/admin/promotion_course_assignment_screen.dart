import 'package:easyedubd_app/features/presentation/screens/admin/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/repository/promotion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromotionCourseAssignmentScreen extends ConsumerStatefulWidget {
  const PromotionCourseAssignmentScreen({
    super.key,
    required this.promotionId,
    required this.promotionName,
  });

  final int promotionId;
  final String promotionName;

  @override
  ConsumerState<PromotionCourseAssignmentScreen> createState() =>
      _PromotionCourseAssignmentScreenState();
}

class _PromotionCourseAssignmentScreenState
    extends ConsumerState<PromotionCourseAssignmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  final Set<int> _assignedIds = <int>{};
  final List<Course> _courses = <Course>[];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadAssignedCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedCourses() async {
    setState(() => _isLoading = true);
    try {
      final ids = await ref
          .read(promotionRepositoryProvider)
          .getCourseIdsForPromotion(widget.promotionId);
      if (mounted) {
        setState(() {
          _assignedIds.addAll(ids);
          _selectedIds.addAll(ids);
        });
      }
    } catch (_) {}
    await _loadCourses();
  }

  Future<void> _loadCourses([String? searchTerm]) async {
    final query = searchTerm?.trim().isEmpty == true
        ? null
        : searchTerm?.trim();
    try {
      final page = await ref.read(
        coursesProvider(CoursesQuery(page: 1, search: query)).future,
      );
      if (mounted) {
        setState(() {
          _courses
            ..clear()
            ..addAll(page.items);
          _isLoading = false;
          _errorText = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString();
        });
      }
    }
  }

  Future<void> _saveAssignments() async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final toAdd = _selectedIds.difference(_assignedIds);
      final toRemove = _assignedIds.difference(_selectedIds);

      for (final id in toAdd) {
        await ref
            .read(promotionRepositoryProvider)
            .assignPromotionToCourse(widget.promotionId, id);
      }
      for (final id in toRemove) {
        await ref
            .read(promotionRepositoryProvider)
            .removePromotionFromCourse(widget.promotionId, id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion courses updated')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Courses · ${widget.promotionName}'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _saveAssignments,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (_searchController.text == value && mounted) {
                    setState(() => _isLoading = true);
                    _loadCourses(value);
                  }
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadCourses(_searchController.text),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Error: $_errorText'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _loadCourses(_searchController.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Text('No courses found. Try a different search.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _courses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final course = _courses[index];
        final checked = _selectedIds.contains(course.id);
        return CheckboxListTile(
          value: checked,
          title: Text(course.title),
          subtitle: Text(
            course.subject.isNotEmpty ? course.subject : 'Course ${course.id}',
          ),
          dense: true,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(course.id);
              } else {
                _selectedIds.remove(course.id);
              }
            });
          },
        );
      },
    );
  }
}
