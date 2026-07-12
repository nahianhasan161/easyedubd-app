import 'package:easyedubd_app/core/providers/auth_notifier.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_device.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_devices_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_management_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/admin/user_repository.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:easyedubd_app/features/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeUserRepository extends UserRepository {
  FakeUserRepository() : super(_client);

  static final _client = SupabaseClient(
    'https://x.supabase.co',
    'k',
  )..auth.stopAutoRefresh();

  final int total = 17;
  final List<(String, String)> updates = [];
  final List<Profile> users = [
    for (int i = 0; i < 17; i++)
      Profile(id: 'u$i', fullName: 'User $i', role: i.isEven ? 'user' : 'admin'),
  ];

  @override
  Future<PaginatedUsers> getUsers({
    required int page,
    int pageSize = 15,
  }) async {
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, users.length);
    final items = users.sublist(start, end);
    return PaginatedUsers(
      items: items,
      total: users.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> updateRole(String id, String role) async {
    updates.add((id, role));
    final i = users.indexWhere((u) => u.id == id);
    if (i != -1) users[i] = users[i].copyWith(role: role);
  }

  final Map<String, List<UserDevice>> deviceMap = {
    'u0': [
      UserDevice(
        id: 'd0',
        userId: 'u0',
        installationId: 'install-0',
        platform: 'android',
        model: 'Pixel',
        approved: false,
        firstSeenAt: DateTime(2024),
        lastSeenAt: DateTime(2024, 6),
        createdAt: DateTime(2024),
      ),
      UserDevice(
        id: 'd1',
        userId: 'u0',
        installationId: 'install-1',
        platform: 'ios',
        model: 'iPhone',
        approved: true,
        firstSeenAt: DateTime(2024),
        lastSeenAt: DateTime(2024, 6),
        createdAt: DateTime(2024),
      ),
    ],
  };
  final List<(String, bool, String)> deviceApprovals = [];

  int getUserDevicesCallCount = 0;

  @override
  Future<List<UserDevice>> getUserDevices(String userId) async {
    getUserDevicesCallCount++;
    return deviceMap[userId] ?? [];
  }

  @override
  Future<void> setDeviceApproved({
    required String deviceId,
    required bool approved,
    required String adminId,
    DateTime? revokedAt,
  }) async {
    deviceApprovals.add((deviceId, approved, adminId));
    for (final list in deviceMap.values) {
      final i = list.indexWhere((d) => d.id == deviceId);
      if (i != -1) {
        list[i] = list[i].copyWith(
          approved: approved,
          approvedAt: approved ? DateTime(2024, 7) : null,
          approvedBy: approved ? adminId : null,
          revokedAt: approved ? null : revokedAt,
        );
      }
    }
  }
}

class StubAuthController extends AuthController {
  @override
  Future<Session?> build() async => null;

  @override
  Future<void> logout() async {}
}

Finder buttonInTile(String name) {
  final tile = find.ancestor(
    of: find.text(name),
    matching: find.byType(ListTile),
  );
  return find.descendant(of: tile, matching: find.byType(FilledButton));
}

void main() {
  testWidgets('menu button opens drawer with User Management for admins', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://x.supabase.co',
        anonKey: 'k',
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      );
    } catch (_) {
      // already initialized in this process
    }

    final admin = Profile(id: 'admin-1', fullName: 'Admin User', role: 'admin');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(true),
          currentProfileProvider.overrideWithValue(AsyncData(admin)),
          authControllerProvider.overrideWith(() => StubAuthController()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Drawer content not present until opened.
    expect(find.text('User Management'), findsNothing);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    // Drawer opened and shows the admin option.
    expect(find.text('User Management'), findsOneWidget);
  });

  testWidgets('non-admin does not see User Management in drawer', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://x.supabase.co',
        anonKey: 'k',
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      );
    } catch (_) {
      // already initialized in this process
    }

    final user = Profile(id: 'user-1', fullName: 'Normal User', role: 'user');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(false),
          currentProfileProvider.overrideWithValue(AsyncData(user)),
          authControllerProvider.overrideWith(() => StubAuthController()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('User Management'), findsNothing);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('user management lists users, paginates and changes role', (
    tester,
  ) async {
    final fake = FakeUserRepository();

    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(true),
          userRepositoryProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(home: UserManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final nextButton = find.ancestor(
      of: find.byTooltip('Next'),
      matching: find.byType(IconButton),
    );
    final previousButton = find.ancestor(
      of: find.byTooltip('Previous'),
      matching: find.byType(IconButton),
    );

    // Page 1
    expect(find.text('User 0'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.textContaining('of 17'), findsOneWidget);
    expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);

    // Promote User 0
    await tester.tap(buttonInTile('User 0'));
    await tester.pumpAndSettle();

    expect(fake.updates, contains(const ('u0', 'admin')));
    // User 0 now shows the Admin chip and a "Make User" button.
    expect(
      find.descendant(
        of: buttonInTile('User 0'),
        matching: find.text('Make User'),
      ),
      findsOneWidget,
    );

    // Dismiss the success SnackBar so it doesn't cover the pagination bar.
    ScaffoldMessenger.of(
      tester.element(find.byType(UserManagementScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Go to page 2
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('User 15'), findsOneWidget);
    expect(find.text('User 0'), findsNothing);
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(tester.widget<IconButton>(nextButton).onPressed, isNull);
    expect(tester.widget<IconButton>(previousButton).onPressed, isNotNull);

    // Back to page 1
    await tester.ensureVisible(previousButton);
    await tester.pumpAndSettle();
    await tester.tap(previousButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('User 0'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('admin can approve and revoke a user device', (tester) async {
    final fake = FakeUserRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(true),
          userRepositoryProvider.overrideWithValue(fake),
          currentUserIdProvider.overrideWithValue('admin-1'),
        ],
        child: const MaterialApp(
          home: UserDevicesScreen(userId: 'u0', userName: 'User 0'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('install-0'), findsOneWidget);
    expect(find.textContaining('install-1'), findsOneWidget);

    final initials = tester
        .widgetList<DropdownButton<DeviceStatus>>(
          find.byType(DropdownButton<DeviceStatus>),
        )
        .toList();
    expect(initials[0].value, DeviceStatus.pending); // d0
    expect(initials[1].value, DeviceStatus.approved); // d1
    expect(find.text('Pending approval'), findsAtLeastNWidgets(1));
    expect(find.text('Approved'), findsAtLeastNWidgets(1));

    // Approve d0 via the dropdown
    await tester.tap(find.byType(DropdownButton<DeviceStatus>).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('d0_approved')));
    await tester.pumpAndSettle();

    expect(
      fake.deviceApprovals,
      contains(const ('d0', true, 'admin-1')),
    );
    expect(
      tester
          .widgetList<DropdownButton<DeviceStatus>>(
            find.byType(DropdownButton<DeviceStatus>),
          )
          .toList()[0]
          .value,
      DeviceStatus.approved,
    );
    expect(find.text('Pending approval'), findsNothing);
    expect(find.text('Approved'), findsAtLeastNWidgets(2));

    // Dismiss snackbar, then block d1
    ScaffoldMessenger.of(
      tester.element(find.byType(UserDevicesScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<DeviceStatus>).at(1), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('d1_blocked')));
    await tester.pumpAndSettle();

    expect(
      fake.deviceApprovals,
      contains(const ('d1', false, 'admin-1')),
    );
    expect(
      tester
          .widgetList<DropdownButton<DeviceStatus>>(
            find.byType(DropdownButton<DeviceStatus>),
          )
          .toList()[1]
          .value,
      DeviceStatus.blocked,
    );
    expect(find.text('Blocked'), findsAtLeastNWidgets(1));
  });

  testWidgets('pull-to-refresh reloads the device list', (tester) async {
    final fake = FakeUserRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(true),
          userRepositoryProvider.overrideWithValue(fake),
          currentUserIdProvider.overrideWithValue('admin-1'),
        ],
        child: const MaterialApp(
          home: UserDevicesScreen(userId: 'u0', userName: 'User 0'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.getUserDevicesCallCount, 1);

    await tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();

    expect(fake.getUserDevicesCallCount, 2);
  });
}
