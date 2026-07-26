import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/lessons.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/chapter.dart';
import 'package:easyedubd_app/core/providers/course_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LessonPlayerArgs {
  final String title;
  final int? courseId;
  final String? chapterId;
  final String? chapterTitle;
  final String? lessonId;
  final List<Lesson>? lessonsInChapter;
  final List<Chapter>? allChapters;
  final ChapterNav? previousChapter;
  final ChapterNav? nextChapter;

  const LessonPlayerArgs({
    required this.title,
    this.courseId,
    this.chapterId,
    this.chapterTitle,
    this.lessonId,
    this.lessonsInChapter,
    this.allChapters,
    this.previousChapter,
    this.nextChapter,
  });
}

class ChapterNav {
  final String id;
  final String title;
  const ChapterNav({required this.id, required this.title});
}

class LessonPlayer extends ConsumerStatefulWidget {
  final String videoId;
  final String title;
  final int? courseId;
  final String? chapterId;
  final String? lessonId;
  final String? chapterTitle;
  final List<Lesson>? lessonsInChapter;
  final List<Chapter>? allChapters;
  final ChapterNav? previousChapter;
  final ChapterNav? nextChapter;

  const LessonPlayer({
    super.key,
    required this.videoId,
    required this.title,
    this.courseId,
    this.chapterId,
    this.lessonId,
    this.chapterTitle,
    this.lessonsInChapter,
    this.allChapters,
    this.previousChapter,
    this.nextChapter,
  });

  @override
  ConsumerState<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends ConsumerState<LessonPlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  double _currentSpeed = 1.0;
  String? _loadError;
  final Map<String, bool> _completedLessons = {};

  static const List<double> _speedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  @override
  void initState() {
    super.initState();
    _loadError = null;
    _isPlayerReady = false;
    _initializePlayer(widget.videoId);
    _seedCompletedLessons();
  }

  void _seedCompletedLessons() {
    _completedLessons.clear();
    for (final lesson in widget.lessonsInChapter ?? const <Lesson>[]) {
      if (lesson.isCompleted) {
        _completedLessons[lesson.id] = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LessonPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId ||
        oldWidget.lessonsInChapter != widget.lessonsInChapter) {
      _seedCompletedLessons();
    }
  }

  void _initializePlayer(String rawVideoId) {
    final videoId = YoutubePlayer.convertUrlToId(rawVideoId) ?? rawVideoId;

    if (videoId.isEmpty) {
      setState(() => _loadError = 'Invalid video ID');
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    _controller.addListener(() {
      if (!mounted) return;
      final state = _controller.value;
      if (state.hasError) {
        setState(() => _loadError = 'Video unavailable or blocked');
      } else if (state.isPlaying && !_isPlayerReady) {
        setState(() => _isPlayerReady = true);
      }
    });
  }

  Chapter? _findChapterForLesson(Lesson lesson) {
    if (widget.allChapters == null) return null;
    for (final chapter in widget.allChapters!) {
      if (chapter.lessons.any((l) => l.id == lesson.id)) {
        return chapter;
      }
    }
    return null;
  }

  ({ChapterNav? previous, ChapterNav? next}) _chapterNavFor(Chapter targetChapter) {
    if (widget.allChapters == null || widget.allChapters!.isEmpty) {
      return (previous: widget.previousChapter, next: widget.nextChapter);
    }

    final index = widget.allChapters!.indexOf(targetChapter);
    if (index < 0) {
      return (previous: widget.previousChapter, next: widget.nextChapter);
    }

    final previous = index > 0
        ? ChapterNav(
            id: widget.allChapters![index - 1].id,
            title: widget.allChapters![index - 1].title,
          )
        : null;

    final next = index < widget.allChapters!.length - 1
        ? ChapterNav(
            id: widget.allChapters![index + 1].id,
            title: widget.allChapters![index + 1].title,
          )
        : null;

    return (previous: previous, next: next);
  }

  void _switchToLesson(Lesson lesson) {
    if (lesson.videoId.isEmpty) {
      context.push('/lesson', extra: lesson.title);
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(lesson.videoId) ?? lesson.videoId;
    if (videoId.isEmpty) return;

    final targetChapter = _findChapterForLesson(lesson);
    final chapterId = targetChapter?.id ?? widget.chapterId;
    final chapterTitle = targetChapter?.title ?? widget.chapterTitle;
    final lessonsInChapter = targetChapter?.lessons ?? widget.lessonsInChapter;
    final nav = _chapterNavFor(
      targetChapter ??
          widget.allChapters?.first ??
          const Chapter(id: '', title: '', description: '', lessons: []),
    );

    setState(() {
      _isPlayerReady = false;
      _loadError = null;
    });

    _controller.load(videoId, startAt: 0);
    _controller.play();

    final args = LessonPlayerArgs(
      title: lesson.title,
      courseId: widget.courseId,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      lessonId: lesson.id,
      lessonsInChapter: lessonsInChapter,
      allChapters: widget.allChapters,
      previousChapter: nav.previous,
      nextChapter: nav.next,
    );

    if (mounted) {
      context.replace('/lesson/${lesson.videoId}', extra: args);
    }
  }

  void _goToChapter(ChapterNav chapter) {
    if (widget.allChapters == null || widget.allChapters!.isEmpty) return;

    final targetChapter = widget.allChapters!.firstWhere(
      (c) => c.id == chapter.id,
      orElse: () => widget.allChapters!.first,
    );

    final targetLesson = targetChapter.lessons.firstWhere(
      (l) => l.videoId.isNotEmpty,
      orElse: () => targetChapter.lessons.first,
    );

    _switchToLesson(targetLesson);
  }

  void _showSpeedPicker() {
    if (!_isPlayerReady) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Playback Speed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._speedOptions.map((speed) {
                return ListTile(
                  title: Text('${speed}x'),
                  trailing: _currentSpeed == speed
                      ? const Icon(Icons.check, color: Colors.red)
                      : null,
                  onTap: () {
                    _controller.setPlaybackRate(speed);
                    setState(() => _currentSpeed = speed);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _toggleComplete() async {
    final lessonId = widget.lessonId;
    if (lessonId == null || lessonId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot toggle completion for this lesson'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final current = _completedLessons[lessonId] == true;
    final newValue = !current;

    final repository = ref.read(courseRepositoryProvider);
    try {
      await repository.markLessonComplete(lessonId, isComplete: newValue);
      if (mounted) {
        setState(() {
          if (newValue) {
            _completedLessons[lessonId] = true;
          } else {
            _completedLessons.remove(lessonId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue ? 'Lesson marked as complete' : 'Lesson marked as incomplete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update completion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = widget.lessonsInChapter ?? const <Lesson>[];
    final currentLessonId = widget.lessonId;
    final isCurrentLessonComplete = currentLessonId == null
        ? false
        : (_completedLessons[currentLessonId] == true ||
            (lessons.any((l) => l.id == currentLessonId && l.isCompleted)));

    return PopScope(
      canPop: true,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          onReady: () {
            _controller.play();
            setState(() => _isPlayerReady = true);
          },
        ),
        builder: (context, player) {
          return Stack(
            children: [
              Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: AppBar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  centerTitle: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.chapterTitle != null)
                        Text(
                          widget.chapterTitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                    onPressed: () => context.pop(),
                  ),
                ),
                body: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: player,
                    ),

                    if (widget.chapterTitle != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: theme.colorScheme.surface,
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chapter: ${widget.chapterTitle}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_loadError != null)
                      Container(
                        width: double.infinity,
                        color: Colors.red.shade900,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _loadError!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!_isPlayerReady && _loadError == null)
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: Colors.red,
                        backgroundColor: Colors.white24,
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Pause',
                                onPressed: _isPlayerReady
                                    ? () => _controller.pause()
                                    : null,
                                icon: const Icon(Icons.pause_rounded),
                              ),
                              IconButton(
                                tooltip: 'Play',
                                onPressed: _isPlayerReady
                                    ? () => _controller.play()
                                    : null,
                                icon: const Icon(Icons.play_arrow_rounded),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _toggleComplete,
                            icon: Icon(
                              isCurrentLessonComplete
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: isCurrentLessonComplete ? Colors.green : null,
                            ),
                            label: Text(
                              isCurrentLessonComplete ? 'Completed' : 'Mark as Complete',
                              style: TextStyle(
                                color: isCurrentLessonComplete ? Colors.green : null,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Playback Speed',
                                onPressed: _isPlayerReady ? _showSpeedPicker : null,
                                icon: Text(
                                  '${_currentSpeed}x',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Fullscreen',
                                onPressed: _isPlayerReady
                                    ? () => _controller.toggleFullScreenMode()
                                    : null,
                                icon: const Icon(Icons.fullscreen_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (currentLessonId != null && lessons.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: Text(
                          'Other lessons in this chapter',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: lessons.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final lesson = lessons[index];
                            final isCurrent = lesson.id == currentLessonId;
                            final isComplete = lesson.isCompleted;
                            final effectiveComplete = isCurrent ? isCurrentLessonComplete : isComplete;
                            return Material(
                              color: isCurrent
                                  ? isCurrentLessonComplete
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : theme.colorScheme.primaryContainer
                                  : isComplete
                                      ? Colors.green.withValues(alpha: 0.08)
                                      : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                enabled: !isCurrent,
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isCurrent
                                      ? isCurrentLessonComplete
                                          ? Colors.green
                                          : theme.colorScheme.primary
                                      : isComplete
                                          ? Colors.green
                                          : Colors.grey.shade200,
                                  child: Icon(
                                    effectiveComplete
                                        ? Icons.check
                                        : isCurrent
                                            ? Icons.volume_up
                                            : Icons.play_arrow,
                                    size: 16,
                                    color: (isCurrent || effectiveComplete) ? Colors.white : Colors.black54,
                                  ),
                                ),
                                title: Text(
                                  lesson.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    color: effectiveComplete ? Colors.green : null,
                                  ),
                                ),
                                subtitle: Text('${lesson.duration.inMinutes} min'),
                                trailing: isCurrent
                                    ? Icon(Icons.equalizer,
                                        size: 18, color: isCurrentLessonComplete ? Colors.green : theme.colorScheme.primary)
                                    : isComplete
                                        ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                        : const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: isCurrent ? null : () => _switchToLesson(lesson),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No other lessons available in this chapter.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (widget.previousChapter != null ||
                        widget.nextChapter != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            if (widget.previousChapter != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _goToChapter(widget.previousChapter!),
                                  icon: const Icon(Icons.chevron_left),
                                  label: Text(
                                    widget.previousChapter!.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            if (widget.previousChapter != null &&
                                widget.nextChapter != null)
                              const SizedBox(width: 12),
                            if (widget.nextChapter != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _goToChapter(widget.nextChapter!),
                                  icon: const Icon(Icons.chevron_right),
                                  label: Text(
                                    widget.nextChapter!.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
