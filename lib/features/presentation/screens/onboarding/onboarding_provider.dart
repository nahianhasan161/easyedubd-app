import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _onboardingKey = 'onboarding_completed';

/// Whether the user has completed the onboarding flow.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  return (await _storage.read(key: _onboardingKey)) == 'true';
});

/// Persists onboarding completion. Invalidate [onboardingCompletedProvider]
/// afterwards to refresh dependent routes.
Future<void> completeOnboarding() async {
  await _storage.write(key: _onboardingKey, value: 'true');
}
