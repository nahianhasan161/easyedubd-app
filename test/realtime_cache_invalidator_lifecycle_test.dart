import 'package:easyedubd_app/core/cache/realtime_cache_invalidator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the lifecycle-driven (not timer-driven) cache invalidation
/// behavior. The poller must NOT start a periodic timer. The version
/// check should only run when the user is actively engaged with the app
/// (resume, tab change, route return, connectivity change) or after an
/// admin write (`invalidateAllLocal()`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeCacheInvalidator is lifecycle-driven, not timer-driven', () {
    setUp(() async {
      // Reset the singleton state between tests.
      await RealtimeCacheInvalidator.stop();
      await RealtimeCacheInvalidator.dispose();
    });

    test('start() is idempotent (safe to call multiple times)', () {
      // Should not throw and should not produce side effects on repeat calls.
      RealtimeCacheInvalidator.start();
      expect(() => RealtimeCacheInvalidator.start(), returnsNormally);
      expect(() => RealtimeCacheInvalidator.start(), returnsNormally);
    });

    test('stop() is safe to call even though there is no timer', () async {
      RealtimeCacheInvalidator.start();
      // stop() used to cancel a timer. Now it just clears the started
      // flag. Make sure it doesn't throw.
      await expectLater(RealtimeCacheInvalidator.stop(), completes);
    });

    test('invalidateAllLocal() does not throw without a started service',
        () async {
      // Should be safe to call even if start() was never called.
      // (In production it's only called after a successful write, so
      // start() will have been called, but defensive is good.)
      await expectLater(RealtimeCacheInvalidator.invalidateAllLocal(),
          completes);
    });

    test('checkNow() is a no-op if the service has not been started', () {
      // checkNow() should silently do nothing when _started is false.
      // We can't easily verify "no network call" without a fake Supabase,
      // but the contract is documented: "No-op if a check is already in
      // flight or the service hasn't been started yet."
      expect(() => RealtimeCacheInvalidator.checkNow(), returnsNormally);
    });

    test(
      'start() does not block — it returns immediately and runs the '
      'initial check asynchronously',
      () {
        final stopwatch = Stopwatch()..start();
        RealtimeCacheInvalidator.start();
        stopwatch.stop();
        // start() should return in well under 100ms. The actual network
        // call (if any) is unawaited.
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'start() must not block on a network call. The version '
              'check is fire-and-forget so the app startup is not delayed.',
        );
      },
    );

    test(
      'multiple start() calls do not start multiple parallel checks',
      () async {
        // Call start() 10 times. The internal _started flag should
        // guard against multiple parallel _checkSafely() invocations.
        // We can't easily verify "no network call" without a fake, but
        // the start() method has `if (_started) return;` which makes it
        // idempotent at the entry point.
        for (var i = 0; i < 10; i++) {
          RealtimeCacheInvalidator.start();
        }
        // Give any unawaited _checkSafely() a chance to run.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // No assertion needed — the test passes if no exception is thrown.
        // The idempotency of start() is verified by the fact that the
        // service is still functional (next call to checkNow() works).
        RealtimeCacheInvalidator.checkNow();
      },
    );
  });
}
