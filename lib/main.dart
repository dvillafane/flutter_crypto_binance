// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crypto_binance/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen/login_screen.dart';
import 'screens/home_screen.dart'; // Asegúrate de importar HomeScreen

/// Punto de entrada principal de la aplicación Flutter
void main() async {
  // Asegura que Flutter esté completamente inicializado antes de ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();

  // Carga el archivo .env con las variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error al cargar el archivo .env: $e");
  }
  // Inicializa Firebase con la configuración específica del dispositivo (web, Android, iOS)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/// Widget principal de la aplicación, sin estado (StatelessWidget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título de la app (se usa en algunos dispositivos al cambiar entre apps)
      title: 'Cyptos 2.0 Demo',

      // Define el tema visual general de la app
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,

        // Tema para la AppBar (barra superior)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),

        // Estilo de texto para el cuerpo
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),

        // Tema visual para las tarjetas (Cards)
        cardTheme: CardTheme(color: Colors.grey[900], elevation: 4),

        // Tema visual para diálogos (AlertDialog, etc.)
        dialogTheme: const DialogTheme(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          contentTextStyle: TextStyle(color: Colors.white70),
        ),

        // Usa Material 3 (diseño más moderno)
        useMaterial3: true,
      ),
      home: const AuthCheck(), // Cambia home a AuthCheck
    );
  }
}

// Nuevo widget para verificar el estado de autenticación
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se verifica el estado, muestra un indicador de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Si hay un usuario autenticado, redirige a HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Si no hay usuario, muestra LoginPage
        return const LoginPage();
      },
    );
  }
}
