import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push notifications.
///
/// WHY EVERY PATH IN HERE IS SURVIVABLE
///
/// Firebase needs `google-services.json` on Android and
/// `GoogleService-Info.plist` plus an APNs key on iOS. Those live outside
/// the repository, so on a fresh checkout — or on a simulator, which has no
/// APNs at all — `Firebase.initializeApp()` throws. Push is a feature of
/// DSH, not a precondition for it, so nothing here is allowed to stop the
/// app from starting. Every failure logs and disables push.
///
/// WHAT THE THREE MESSAGE STATES MEAN
///
/// A push arrives in one of three situations and each is handled elsewhere:
///
///   • app in the foreground — the OS shows nothing, so the banner is drawn
///     by flutter_local_notifications here;
///   • app in the background — the OS shows it, and a tap wakes the app
///     with `onMessageOpenedApp`;
///   • app terminated — the OS shows it, and the tap that launched the app
///     is read once from `getInitialMessage()`.
///
/// Missing the third is the classic bug: everything works in testing, and
/// tapping a notification on a cold phone opens the app on Home.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  static const _channelId = 'dsh_default';

  final _local = FlutterLocalNotificationsPlugin();

  /// Emits the in-app route a tapped notification asked for. The router
  /// listens; this class deliberately knows nothing about navigation.
  final _taps = StreamController<String>.broadcast();
  Stream<String> get onTapRoute => _taps.stream;

  bool _ready = false;
  String? _token;

  /// Whether push actually came up. False on a simulator, on a build with no
  /// Firebase config, and when the user declined the permission.
  bool get isAvailable => _ready;
  String? get token => _token;

  /// Called once from main(), before runApp.
  ///
  /// Returns rather than throws: a missing Firebase config is a deployment
  /// state, not a programming error, and the app is fully usable without it.
  Future<void> init() async {
    try {
      // No FirebaseOptions: the native config files are the source of truth,
      // so there is no generated firebase_options.dart to drift from them.
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[push] Firebase unavailable, notifications disabled: $e');
      return;
    }

    try {
      // Attached after initializeApp, before any listener: the plugin needs
      // a live Firebase app to hand the callback's entry point to the
      // background isolate.
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      await _setUpLocalNotifications();
      await _requestPermission();
      await _bindMessageHandlers();
      _ready = true;
    } catch (e) {
      debugPrint('[push] setup failed, notifications disabled: $e');
    }
  }

  Future<void> _setUpLocalNotifications() async {
    await _local.initialize(
      const InitializationSettings(
        // @mipmap/ic_launcher rather than a dedicated asset: a monochrome
        // notification icon is a design task, and an icon that does not
        // exist makes Android drop the notification silently.
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // All three default to true, but iOS asks for them at initialize()
        // time; requesting here would show the permission dialog before the
        // app has explained itself. _requestPermission() does it instead.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) _taps.add(route);
      },
    );

    if (Platform.isAndroid) {
      // Created explicitly so its name and importance are ours. Left to
      // Android's default, DSH notifications arrive at low importance with
      // no heads-up banner.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              'Don\'t Skip Humanity',
              description: 'New films, episodes and course announcements.',
              importance: Importance.high,
            ),
          );
    }
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[push] permission denied');
      return;
    }

    // On iOS the FCM token is only issued once APNs has handed over its own,
    // which can lag the permission grant by a moment. Without this the first
    // getToken() after a fresh install returns null and the device never
    // registers until the next launch.
    if (Platform.isIOS) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns == null) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _bindMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_showForeground);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'];
      if (route is String && route.isNotEmpty) _taps.add(route);
    });

    // The tap that launched the app from terminated. Read once — leaving it
    // unread means it replays on every hot restart in development.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    final route = initial?.data['route'];
    if (route is String && route.isNotEmpty) {
      // Deferred: the router does not exist yet at init() time, so emitting
      // now would go to a stream nobody is listening to.
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        _taps.add(route);
      });
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Don\'t Skip Humanity',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String? ?? '',
    );
  }

  /// Tell the backend this device exists, and keep telling it.
  ///
  /// Called on launch and again whenever the signed-in user or the language
  /// changes, because both are columns on the device row that the dashboard
  /// filters on. Registration is an upsert keyed on the token, so calling it
  /// often is cheap and calling it twice is harmless.
  Future<void> registerDevice({required String locale}) async {
    if (!_ready) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      _token = token;

      await _upsert(token, locale);

      // FCM rotates tokens on its own schedule — reinstall, restore from
      // backup, or roughly yearly. Without this the device goes quiet and
      // nothing in the dashboard explains why.
      FirebaseMessaging.instance.onTokenRefresh.listen((fresh) {
        _token = fresh;
        _upsert(fresh, locale);
      });
    } catch (e) {
      debugPrint('[push] could not register device: $e');
    }
  }

  Future<void> _upsert(String token, String locale) async {
    // An RPC rather than a table write: push_devices has no client-writable
    // policy, so a guest with no auth.uid() could not insert a row at all.
    await Supabase.instance.client.rpc('register_push_device', params: {
      'p_token': token,
      'p_platform': Platform.isIOS ? 'ios' : 'android',
      'p_locale': locale,
      'p_app_version': '',
      'p_device_model': '',
    });
  }

  /// Sign-out: the device keeps receiving broadcasts but stops being
  /// attributable to a person, so it drops out of every personal send.
  ///
  /// The token is deliberately NOT deleted. Deleting it would mean the next
  /// launch has to wait for a fresh one before it can receive anything.
  Future<void> releaseDevice() async {
    final token = _token;
    if (token == null) return;

    try {
      await Supabase.instance.client
          .rpc('release_push_device', params: {'p_token': token});
    } catch (e) {
      debugPrint('[push] could not release device: $e');
    }
  }

  /// Clears the iOS badge. Called when the inbox is opened and read.
  Future<void> clearBadge() async {
    if (!_ready) return;
    try {
      await _local.cancelAll();
    } catch (_) {
      // Cosmetic; never worth surfacing.
    }
  }
}

/// Background isolate entry point.
///
/// Must be a top-level function annotated for release builds, or the tree
/// shaker removes it and background messages stop arriving in the very
/// builds that ship. It runs in its own isolate with no access to anything
/// the app has in memory, which is why it does nothing but let Firebase
/// finish — the OS draws the notification itself from the payload.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
