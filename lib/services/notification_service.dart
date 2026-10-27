import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Professional Local Notification Service for FoodCourt Mobile Application.
/// Handles instant heads-up banners, background order status updates,
/// arrival notifications when rider reaches the customer pin,
/// and scheduled meal / daig booking reminders.
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Notification Channel IDs
  static const String orderChannelId = 'foodcourt_order_channel';
  static const String orderChannelName = 'FoodCourt Orders & Delivery Alerts';
  static const String orderChannelDesc =
      'Real-time alerts for kitchen order confirmations, cooking, rider departure, and arrival at customer doorstep.';

  static const String reminderChannelId = 'foodcourt_reminder_channel';
  static const String reminderChannelName = 'FoodCourt Meal & Booking Reminders';
  static const String reminderChannelDesc =
      'Scheduled meal time notifications and advance Daig delivery alerts.';

  /// Callback when a user taps on any notification banner
  Function(String? payload)? onNotificationTapped;

  /// Initialize local notification plugins, channels, and timezones
  Future<void> init({Function(String? payload)? onTap}) async {
    if (_isInitialized) return;

    if (onTap != null) {
      onNotificationTapped = onTap;
    }

    try {
      // 1. Initialize timezone databases
      tz.initializeTimeZones();

      // 2. Platform initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open Notification');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      // 3. Initialize plugin with click callback
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification tapped: ${response.payload}');
          onNotificationTapped?.call(response.payload);
        },
      );

      // 4. Request notification permissions on Android 13+
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            final androidImpl = _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

            // Request POST_NOTIFICATIONS permission
            await androidImpl?.requestNotificationsPermission();

            // Create High Priority Order Updates Channel
            const AndroidNotificationChannel orderChannel =
                AndroidNotificationChannel(
              orderChannelId,
              orderChannelName,
              description: orderChannelDesc,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            );

            // Create Reminder Channel
            const AndroidNotificationChannel reminderChannel =
                AndroidNotificationChannel(
              reminderChannelId,
              reminderChannelName,
              description: reminderChannelDesc,
              importance: Importance.defaultImportance,
              playSound: true,
              enableVibration: true,
            );

            await androidImpl?.createNotificationChannel(orderChannel);
            await androidImpl?.createNotificationChannel(reminderChannel);
          }
        } catch (platformErr) {
          debugPrint('[NotificationService] Platform channel setup note: $platformErr');
        }
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully!');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Base Notification Details for Order Tracking (Heads-up alert)
  NotificationDetails _getOrderNotificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      orderChannelId,
      orderChannelName,
      channelDescription: orderChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  /// Show generic order update notification
  Future<void> showOrderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('[NotificationService] Not initialized, queued/skipped notification: "$title"');
      return;
    }
    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _getOrderNotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showOrderNotification error: $e');
    }
  }

  /// 🛵 Dedicated Rider Arrived Notification (Customer Specific)
  /// Triggered when rider marks 'Arrived' or GPS distance reaches doorstep
  Future<void> showRiderArrivedNotification({
    required String orderId,
    String? riderName,
    required String address,
  }) async {
    final int notifId = _generateIdFromString('ARRIVE_$orderId');
    final String riderDisplay = (riderName != null && riderName.isNotEmpty)
        ? riderName
        : 'Aap ka delivery rider';

    await showOrderNotification(
      id: notifId,
      title: '🛵 Rider Arrived at Your Location! 📍',
      body:
          '$riderDisplay aapki dehleez ($address) par pohanch chuka hai! Baraye meherbani apna order collect karein.',
      payload: 'ORDER_$orderId',
    );
  }

  /// Automatic status change dispatcher
  Future<void> showStatusUpdateNotification({
    required String orderId,
    required String newStatus,
    String? restaurantName,
    String? riderName,
    String? address,
  }) async {
    final int notifId = _generateIdFromString('${orderId}_$newStatus');
    final String rest = (restaurantName != null && restaurantName.isNotEmpty)
        ? restaurantName
        : 'FoodCourt';

    String title;
    String body;

    switch (newStatus.trim().toLowerCase()) {
      case 'accepted':
        title = '✅ Order Confirmed! (#$orderId)';
        body =
            'Aapka order $rest ne confirm kar liya hai. Kitchen tayyari shuru karne laga hai!';
        break;

      case 'preparing':
        title = '👨‍🍳 Khana Tayyar Ho Raha Hai (#$orderId)';
        body =
            '$rest aapka mazedaar khana taaza cook kar raha hai. Jaldi rider pick karega.';
        break;

      case 'on the way':
        title = '🛵 Rider Nikal Chuka Hai! (#$orderId)';
        final rName = (riderName != null && riderName.isNotEmpty) ? riderName : 'Rider';
        body =
            '$rName aapka order le kar nikal chuka hai aur Google Maps GPS route follow kar raha hai!';
        break;

      case 'arrived':
        await showRiderArrivedNotification(
          orderId: orderId,
          riderName: riderName,
          address: address ?? 'Aapki Location',
        );
        return;

      case 'delivered':
        title = '🎉 Order Deliver Ho Gaya! (#$orderId)';
        body =
            'Aapka order kamiyabi se pohanch gaya hai. Lazeez khana enjoy karein aur apna review dein!';
        break;

      case 'cancelled':
      case 'rejected':
        title = '❌ Order Cancelled (#$orderId)';
        body =
            'Aapka order cancel kar diya gaya hai. Mazeed maloomat ke liye support se rabta karein.';
        break;

      default:
        title = '📦 Order Update (#$orderId)';
        body = 'Aapke order ka status ab "$newStatus" ho gaya hai.';
    }

    await showOrderNotification(
      id: notifId,
      title: title,
      body: body,
      payload: 'ORDER_$orderId',
    );
  }

  /// ⏰ Scheduled Notification (e.g. Lunch / Dinner reminder or Daig Booking Delivery)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('[NotificationService] Not initialized, skipped schedule: "$title"');
      return;
    }
    try {
      final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Do not schedule if the time is already passed
      if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('[NotificationService] Scheduled date $tzDate is in the past, skipping.');
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        reminderChannelId,
        reminderChannelName,
        channelDescription: reminderChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );

      debugPrint('[NotificationService] Notification scheduled for $tzDate (ID: $id)');
    } catch (e) {
      debugPrint('[NotificationService] scheduleNotification error: $e');
    }
  }

  /// Helper: Schedule advance Daig Booking Reminder (e.g. 2 hours before event)
  Future<void> scheduleDaigBookingReminder({
    required String orderId,
    required String occasion,
    required DateTime eventTime,
  }) async {
    final reminderTime = eventTime.subtract(const Duration(hours: 2));
    final int notifId = _generateIdFromString('DAIG_$orderId');

    await scheduleNotification(
      id: notifId,
      title: '🍲 Shahi Daig Delivery Reminder! ($occasion)',
      body:
          'Aapki Daig Booking (#$orderId) taqreeban 2 ghante baad delivery ke liye pohanchne wali hai. Dawat ki tayyari mukammal rakhein!',
      scheduledDate: reminderTime,
      payload: 'ORDER_$orderId',
    );
  }

  /// Instant Demo Notification for live user testing
  Future<void> showDemoArrivalTestNotification() async {
    await showRiderArrivedNotification(
      orderId: 'FC-9481',
      riderName: 'Captain Ali Raza',
      address: 'House 42, Block H, Phase 5, DHA, Lahore',
    );
  }

  /// Instant Demo Scheduled Reminder for testing
  Future<void> scheduleDemoMealReminderInSeconds({int seconds = 10}) async {
    final targetTime = DateTime.now().add(Duration(seconds: seconds));
    await scheduleNotification(
      id: 99911,
      title: '🍽️ FoodCourt: Dawat ka Waqt Ho Gaya!',
      body: 'Lunch ka time shuru ho chuka hai! Apna manpasand Shahi Pakwan ya Biryani abhi order karein.',
      scheduledDate: targetTime,
      payload: 'PROMO_LUNCH',
    );
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Cancel all active notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Helper to convert string IDs (like "FC-9481") into integer IDs
  int _generateIdFromString(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = (31 * hash + text.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash % 100000;
  }
}
