import 'package:easyedubd_app/features/presentation/screens/courses/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile model', () {
    final json = {
      'id': 'abc',
      'full_name': 'Nahian Hasan',
      'avatar_url': 'https://x/y.png',
      'created_at': '2024-01-01T00:00:00.000Z',
      'current_level': 'Honours',
      'institute': 'DU',
      'faculty': 'Science',
      'department': 'Chemistry',
      'session': '2020-21',
      'current_year': '2nd',
    };

    test('fromJson maps session (not the old "sesson" typo)', () {
      final p = Profile.fromJson(json);
      expect(p.session, '2020-21');
    });

    test('toUpsertJson uses correct "session" key and omits created_at', () {
      final p = Profile.fromJson(json);
      final map = p.toUpsertJson();
      expect(map.containsKey('session'), isTrue);
      expect(map.containsKey('sesson'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['id'], 'abc');
      expect(map['full_name'], 'Nahian Hasan');
    });

    test('missing fields default to null without throwing', () {
      final p = Profile.fromJson({'id': 'x'});
      expect(p.session, isNull);
      expect(p.fullName, isNull);
    });
  });
}
