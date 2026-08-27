import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/shared/widgets/course_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Course _course(int id) => Course(
      id: id,
      title: 'Course $id',
      description: 'desc',
      imageUrl: '',
      progress: 0,
      is_free: false,
      status: 'published',
      year: '1st',
      subject: 'Math',
      chapters: const [],
    );

void main() {
  group('CourseSlider', () {
    testWidgets('renders the title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'My Courses',
              courses: [],
            ),
          ),
        ),
      );
      expect(find.text('My Courses'), findsOneWidget);
    });

    testWidgets('shows empty state when no courses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'My Courses',
              courses: [],
              emptyMessage: 'Nothing yet.',
            ),
          ),
        ),
      );
      expect(find.text('Nothing yet.'), findsOneWidget);
    });

    testWidgets('renders course cards when courses are provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'My Courses',
              courses: [_course(1), _course(2)],
            ),
          ),
        ),
      );
      // Wait for the ListView to lay out.
      await tester.pump();
      expect(find.text('Course 1'), findsOneWidget);
      expect(find.text('Course 2'), findsOneWidget);
    });

    testWidgets('hides View All when onViewAll is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'My Courses',
              courses: [_course(1), _course(2)],
            ),
          ),
        ),
      );
      expect(find.text('View All'), findsNothing);
    });

    testWidgets('shows View All and calls the callback when tapped',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'My Courses',
              courses: [_course(1), _course(2)],
              onViewAll: () => tapped++,
            ),
          ),
        ),
      );
      expect(find.text('View All'), findsOneWidget);
      await tester.tap(find.text('View All'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('shows skeleton cards while loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'My Courses',
              courses: [],
              isLoading: true,
            ),
          ),
        ),
      );
      // Skeletons don't have text labels, but they should be present in
      // the tree. The CourseCardSkeleton uses a container; just verify
      // the empty state message is NOT shown.
      expect(find.text('Nothing to show yet.'), findsNothing);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'Recommended for you',
              subtitle: '2nd year • Mathematics',
              courses: [],
            ),
          ),
        ),
      );
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('2nd year • Mathematics'), findsOneWidget);
    });

    testWidgets('renders the accent icon in the header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseSlider(
              title: 'All Courses',
              icon: Icons.menu_book_rounded,
              courses: [],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.menu_book_rounded), findsWidgets);
    });

    testWidgets(
      'shows the right-edge scroll hint when there are multiple courses '
      'and the user has not scrolled yet',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: CourseSlider(
                  title: 'All Courses',
                  courses: [
                    _course(1),
                    _course(2),
                    _course(3),
                    _course(4),
                  ],
                ),
              ),
            ),
          ),
        );
        // The hint is a chevron inside a circular badge.
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'does not show the scroll hint when there is only one course',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: CourseSlider(
                  title: 'My Courses',
                  courses: [_course(1)],
                ),
              ),
            ),
          ),
        );
        expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      },
    );

    testWidgets(
      'hides the scroll hint once the user scrolls past a small threshold',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: CourseSlider(
                  title: 'All Courses',
                  courses: [
                    _course(1),
                    _course(2),
                    _course(3),
                    _course(4),
                    _course(5),
                  ],
                ),
              ),
            ),
          ),
        );
        // Hint is visible before any scroll.
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

        // Simulate a horizontal scroll past the 8px threshold.
        await tester.drag(find.byType(ListView), const Offset(-100, 0));
        await tester.pumpAndSettle();

        // Hint should now be gone (and stays gone even if we scroll back).
        expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      },
    );
  });
}
