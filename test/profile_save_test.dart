import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository() : super(_createClient());

  static SupabaseClient _createClient() {
    final client = SupabaseClient('https://x.supabase.co', 'k');
    // Avoid the 10s periodic auto-refresh timer that breaks widget tests.
    client.auth.stopAutoRefresh();
    return client;
  }

  Profile? stored;
  Profile? saved;

  @override
  Future<Profile?> getProfile(String id) async => stored;

  @override
  Future<Profile> upsertProfile(Profile profile) async {
    saved = profile;
    stored = profile;
    return profile;
  }
}

void main() {
  testWidgets(
    'user can fill and save profile details, which are persisted and shown',
    (tester) async {
      final fake = FakeProfileRepository();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => context.push('/profile'),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fake),
            currentUserIdProvider.overrideWithValue('user-1'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Nothing persisted yet
      expect(find.text('Nahian'), findsNothing);

      // Full Name is the first text field
      await tester.enterText(find.byType(TextFormField).first, 'Nahian');
      await tester.pump();

      // Scroll the Save button into view, then tap it
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save Profile'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save Profile'));
      await tester.pumpAndSettle();

      // 1) Saved to the repository with the right id + values
      expect(fake.saved, isNotNull);
      expect(fake.saved!.id, 'user-1');
      expect(fake.saved!.fullName, 'Nahian');

      // 2) Reopen the profile -> the saved data is shown in the form
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(nameField.controller?.text, 'Nahian');
    },
  );
}
