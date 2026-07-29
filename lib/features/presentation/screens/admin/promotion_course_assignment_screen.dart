import 'package:easyedubd_app/core/network/connectivity_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/course_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/repository/promotion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyedubd_app/shared/widgets/offline_banner.dart';

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
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorText;
  
// Pagination state
   int _currentPage = 1;
   bool _hasMore = true;
   late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadAssignedCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCourses();
    }
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
    // Reset pagination for new search
    _currentPage = 1;
    _hasMore = true;
    
    final query = searchTerm?.trim().isEmpty == true
        ? null
        : searchTerm?.trim();
    
    try {
      setState(() => _isLoading = true);
      
      final page = await ref.read(
        coursesProvider(CoursesQuery(page: _currentPage, search: query)).future,
      );
      
      if (mounted) {
        setState(() {
          _courses
            ..clear()
            ..addAll(page.items);
          _hasMore = page.page < page.totalPages;
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

  Future<void> _loadMoreCourses() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final query = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    
    setState(() => _isLoadingMore = true);
    
    try {
      final page = await ref.read(
        coursesProvider(CoursesQuery(page: _currentPage + 1, search: query)).future,
      );
      
      if (mounted) {
        setState(() {
          _courses.addAll(page.items);
          _hasMore = (page.page + 1) < page.totalPages; // Next page would be currentPage + 1
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  bool get _areAllVisibleSelected {
    if (_courses.isEmpty) return false;
    return _courses.every((course) => _selectedIds.contains(course.id));
  }

  void _onSelectAllChanged(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.addAll(_courses.map((course) => course.id));
      } else {
        _selectedIds.removeWhere((id) => _courses.any((course) => course.id == id));
      }
    });
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
else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _courses.isNotEmpty
                    ? InkWell(
                        onTap: () => _onSelectAllChanged(!_areAllVisibleSelected),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _areAllVisibleSelected,
                                onChanged: _onSelectAllChanged,
                              ),
                              const Text('Select all'),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Save',
                onPressed: _saveAssignments,
              ),
            ],
         ],
      ),
      body: Column(
        children: [
          if (ref.watch(isOffline)) const OfflineBanner(),
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
       controller: _scrollController,
       padding: const EdgeInsets.symmetric(horizontal: 12),
       itemCount: _hasMore ? _courses.length + 1 : _courses.length,
       separatorBuilder: (_, _) => const Divider(height: 1),
       itemBuilder: (context, index) {
         if (index >= _courses.length) {
           return const Padding(
             padding: EdgeInsets.symmetric(vertical: 8),
             child: Center(
               child: SizedBox(
                 width: 24,
                 height: 24,
                 child: CircularProgressIndicator(strokeWidth: 2),
               ),
             ),
           );
         }

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
