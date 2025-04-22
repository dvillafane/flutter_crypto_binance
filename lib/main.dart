import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_crypto_binance/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/noti_service.dart';
import 'core/services/token_service.dart';
import 'features/auth/login/view/login_screen.dart';
import 'features/home/view/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error al cargar el archivo .env: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // Inicializar notificaciones solo en plataformas móviles
    await initializeNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Configurar orientación solo en plataformas móviles
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Configurar notificaciones y tokens solo en plataformas móviles
      obtenerYEnviarTokenFCM();
      obtenerYEnviarFID();
      listenTokenRefresh();
      setupNotificationListeners();
    } else {
      // Configurar Firebase Messaging para la web
      setupWebMessaging();
    }
  }

  void setupWebMessaging() async {
    final messaging = FirebaseMessaging.instance;
    // Solicitar permisos para notificaciones en la web
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Obtener y enviar token en la web
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint('Web FCM Token: $token');
      await enviarTokenAFirestore(token);
    }
    // Escuchar renovaciones de token
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('Web FCM Token renovado: $newToken');
      await enviarTokenAFirestore(newToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyptos 2.0 Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        cardTheme: CardTheme(color: Colors.grey[900], elevation: 4),
        dialogTheme: const DialogTheme(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          contentTextStyle: TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? const HomeScreen() : const LoginPage();
      },
    );
  }
}