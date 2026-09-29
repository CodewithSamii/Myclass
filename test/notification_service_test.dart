import 'package:flutter_test/flutter_test.dart';
import 'package:myclass/core/notifications.dart';

void main() {
  group('NotificationService Contract Tests', () {
    late MockNotificationService service;

    setUp(() {
      service = MockNotificationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('getToken returns mock token', () async {
      final token = await service.getToken();
      expect(token, 'mock-fcm-token');
    });

    test('subscribe and unsubscribe complete without error', () async {
      await expectLater(service.subscribeToSection('bsc-cse-64-I'), completes);
      await expectLater(service.unsubscribeFromSection('bsc-cse-64-I'), completes);
    });

    test('onNotificationTapped stream delivers payload', () async {
      const payload = {
        'sectionId': 'bsc-cse-64-I',
        'eventId': 'event-101',
        'title': 'Networking Exam moved',
      };

      final future = service.onNotificationTapped.first;
      service.simulateNotificationTap(payload);

      final received = await future;
      expect(received, equals(payload));
      expect(received['sectionId'], 'bsc-cse-64-I');
      expect(received['eventId'], 'event-101');
    });
  });
}
