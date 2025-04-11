// services/noti_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

/// Plugin global para manejar notificaciones locales.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Inicializa las notificaciones locales.
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// Manejador de notificaciones en segundo plano.
/// Se ejecuta cuando llega una notificación mientras la app está cerrada o en segundo plano.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('Notificación en segundo plano: ${message.messageId}');
  }
  await _showLocalNotification(message);
}

/// Muestra una notificación local (aplicable en primer plano o en segundo plano).
Future<void> _showLocalNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id', // ID del canal de notificación
          'channel_name', // Nombre del canal
          channelDescription: 'channel_description', // Descripción del canal
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: 'Notification Payload',
    );
  }
}

/// Configura los escuchadores para manejar notificaciones en primer plano.
void setupNotificationListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('Notificación en primer plano: ${message.messageId}');
    }
    _showLocalNotification(message);
  });

  // Solicita permisos al usuario para mostrar notificaciones.
  FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}
