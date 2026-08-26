import 'dart:async';
import 'dart:io' show SocketException;

/// Returns true if the error is a transient network failure (DNS not ready,
/// socket not ready, connection refused, timeout). These are the errors
/// that get thrown when the device just came back online but the OS hasn't
/// fully established the network connection yet, or when a request races
/// with a connectivity change.
bool isTransientNetworkError(Object error) {
  final msg = error.toString().toLowerCase();
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  if (msg.contains('socketexception')) return true;
  if (msg.contains('failed host lookup')) return true;
  if (msg.contains('no address associated with hostname')) return true;
  if (msg.contains('connection refused')) return true;
  if (msg.contains('connection reset')) return true;
  if (msg.contains('network is unreachable')) return true;
  if (msg.contains('timeout')) return true;
  return false;
}

/// Strips hostnames (especially the Supabase URL) and stack traces from a
/// raw error string so we can show it to the user without leaking
/// infrastructure details.
String sanitizeErrorMessage(Object error) {
  String msg = error.toString();
  // Remove anything that looks like a URL.
  msg = msg.replaceAll(RegExp(r'https?://[^\s,)]+'), '<server>');
  // Collapse multi-line stack traces to the first line.
  final newline = msg.indexOf('\n');
  if (newline > 0) {
    msg = msg.substring(0, newline);
  }
  return msg.trim();
}

/// Runs [action] with exponential backoff for transient network errors.
/// Stops retrying as soon as it succeeds or hits a non-transient error.
/// Returns the result of the first successful attempt.
Future<T> retryTransient<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  double backoffFactor = 2.0,
}) async {
  Object? lastError;
  Duration delay = initialDelay;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;
      if (!isTransientNetworkError(e) || attempt == maxAttempts) {
        rethrow;
      }
      await Future.delayed(delay);
      delay = delay * backoffFactor;
    }
  }
  // Unreachable, but the type system needs it.
  throw lastError ?? StateError('retryTransient: no attempts made');
}
