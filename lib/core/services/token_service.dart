// services/token_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter/foundation.dart';

/// Envía el token FCM a Firestore en la colección "tokens".
Future<void> enviarTokenAFirestore(String token) async {
  await FirebaseFirestore.instance.collection('tokens').doc(token).set({
    'token': token,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

/// Envía el Firebase Installation ID (FID) a Firestore en la colección "installations".
Future<void> enviarFIDAFirestore(String fid) async {
  await FirebaseFirestore.instance.collection('installations').doc(fid).set({
    'fid': fid,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

/// Obtiene el token FCM y lo envía a Firestore.
Future<void> obtenerYEnviarTokenFCM() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();

  if (token != null) {
    if (kDebugMode) {
      print('Registration Token: $token');
    }
    await enviarTokenAFirestore(token);
  }
}

/// Obtiene el Firebase Installation ID y lo envía a Firestore.
Future<void> obtenerYEnviarFID() async {
  String fid = await FirebaseInstallations.instance.getId();
  if (kDebugMode) {
    print('Firebase Installation ID: $fid');
  }
  await enviarFIDAFirestore(fid);
}

/// Escucha la renovación del token FCM y actualiza Firestore cuando se reciba un nuevo token.
void listenTokenRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    if (kDebugMode) {
      print('Nuevo token recibido: $newToken');
    }
    await enviarTokenAFirestore(newToken);
  });
}
