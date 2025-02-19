import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../view_model/auth_view_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late AuthViewModel authViewModel;

  late String _token;

  String get getFcmToken => _token;

  Future<void> initialize() async {
    // 백그라운드 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 권한 요청
    await _requestPermission();

    // 로컬 알림 초기화
    await setupFlutterNotifications();

    // 메시지 핸들러 설정
    await _setupMessageHandlers();

    // FCM 토큰 조회
    _token = (await _messaging.getToken())!;
    print('FCM Token: $_token');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('권한 상태: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드에서 메시지 수신!');
      print('메시지 데이터: ${message.data}');

      if (message.notification != null) {
        print('메시지에 알림 포함됨: ${message.notification}');
        showNotification(message).catchError((e) {
          print('알림 표시 중 오류 발생: $e');
        });
      }
    });

    // 백그라운드에서 메시지 클릭 시 핸들러
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('메시지 클릭됨!');
      _handleBackgroundMessage(message);
    });

    // 앱이 알림을 통해 시작된 경우 초기 메시지 처리
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    try {
      // navigatorKey를 통해 현재 컨텍스트 접근
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('Navigator 컨텍스트가 null입니다.');
        return;
      }

      authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      /* if (authViewModel.isLoggedIn) {
        navigatorKey.currentState?.pushNamed('/home_screen');
      } else {
        navigatorKey.currentState?.pushNamed('/auth_screen');
      }*/

      showNotification(message).catchError((e) {
        print('알림 표시 중 오류 발생: $e');
      });
    } catch (e) {
      print('백그라운드 메시지 처리 중 오류 발생: $e');
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    try {
      // 로컬 알림 설정 확인
      await setupFlutterNotifications();

      // 알림 세부사항 정의
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'default_channel_id',
        'Default Channel',
        channelDescription: '이 채널은 기본 알림 채널입니다.',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // 알림 표시
      print(
          '알림 표시: ${message.notification?.title} - ${message.notification?.body}');

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? '제목 없음',
        message.notification?.body ?? '내용 없음',
        notificationDetails,
        payload: message.data['payload'] ?? '',
      );
    } catch (e) {
      print('showNotification에서 예외 발생: $e');
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // 알림 탭 시 처리
          print('알림 탭됨, 페이로드: ${details.payload}');
          if (details.payload != null) {
            // 필요 시 페이로드에 따라 네비게이션 수행
          }
        },
      );

      _isFlutterLocalNotificationsInitialized = true;
      print('Flutter 로컬 알림 초기화 완료');
    } catch (e) {
      print('로컬 알림 초기화 중 오류 발생: $e');
    }
  }
}
