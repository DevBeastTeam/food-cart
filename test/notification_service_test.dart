import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery/services/notification_service.dart';
import 'package:food_delivery/state/user_state.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(milliseconds: 100);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('NotificationService Tests', () {
    test('NotificationService singleton initializes and exposes channels', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
      expect(NotificationService.orderChannelId, 'foodcourt_order_channel');
      expect(NotificationService.reminderChannelId, 'foodcourt_reminder_channel');
    });

    test('UserState tracks order status changes and invokes notifications', () async {
      final userState = UserState(enablePeriodicSync: false);
      addTearDown(() => userState.dispose());

      expect(userState.orders.isNotEmpty, isTrue);
      final initialOrder = userState.orders.first;
      expect(initialOrder.status.isNotEmpty, isTrue);

      // Update to On the Way
      userState.updateOrderStatus(initialOrder.id, 'On the Way');
      expect(userState.orders.first.status, 'On the Way');

      // Update to Arrived
      userState.updateOrderStatus(initialOrder.id, 'Arrived');
      expect(userState.orders.first.status, 'Arrived');

      // Update to Delivered
      userState.updateOrderStatus(initialOrder.id, 'Delivered');
      expect(userState.orders.first.status, 'Delivered');
    });

    test('UserState assigns rider and updates status to On the Way', () {
      final userState = UserState(enablePeriodicSync: false);
      addTearDown(() => userState.dispose());

      final orderId = userState.orders.first.id;
      userState.assignRider(orderId, riderName: 'Captain Usman', riderPhone: '+92 300 1234567');

      final order = userState.orders.firstWhere((o) => o.id == orderId);
      expect(order.status, 'On the Way');
      expect(order.riderName, 'Captain Usman');
      expect(order.riderPhone, '+92 300 1234567');
    });
  });
}
