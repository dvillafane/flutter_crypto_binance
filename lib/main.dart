// Importa Firebase Core para inicializar Firebase en la app
import 'package:firebase_core/firebase_core.dart';
// Importa Flutter y su framework de diseño de UI
import 'package:flutter/material.dart';
// Importa las opciones de configuración de Firebase generadas automáticamente
import 'package:flutter_crypto_binance/firebase_options.dart';
// Importa flutter_dotenv para manejar variables de entorno
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Importa la pantalla principal de la aplicación
import 'screens/home_screen.dart';

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

  // Inicia la aplicación llamando a MyApp (el widget principal)
  runApp(MyApp());
}

/// Widget principal de la aplicación, sin estado (StatelessWidget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título de la app (se usa en algunos dispositivos al cambiar entre apps)
      title: 'CoinCap API 2.0 Demo',

      // Define el tema visual general de la app
      theme: ThemeData(
        brightness: Brightness.dark, // Activa modo oscuro
        primaryColor: Colors.black, // Color principal: negro
        // Fondo negro para toda la app (pantallas Scaffold)
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
        cardTheme: CardTheme(
          color: Colors.grey[900], // Fondo oscuro para tarjetas
          elevation: 4, // Elevación para sombra
        ),

        // Tema visual para diálogos (AlertDialog, etc.)
        dialogTheme: const DialogTheme(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          contentTextStyle: TextStyle(color: Colors.white70),
        ),

        // Usa Material 3 (diseño más moderno)
        useMaterial3: true,
      ),

      // Pantalla inicial que se muestra al arrancar la app
      home: HomeScreen(),
    );
  }
}