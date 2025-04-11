import 'package:firebase_core/firebase_core.dart'; // Inicializa Firebase en la app.
import 'package:flutter/material.dart'; // Librería principal para construir interfaces en Flutter.
import 'package:flutter/services.dart'; // Permite controlar configuraciones del sistema, como la orientación.
import 'package:flutter_crypto_binance/firebase_options.dart'; // Configuración específica de Firebase para esta plataforma.
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Permite cargar variables de entorno desde un archivo .env.
import 'package:firebase_auth/firebase_auth.dart'; // Proporciona funcionalidades de autenticación de Firebase.
import 'package:firebase_messaging/firebase_messaging.dart'; // Permite manejar notificaciones push con FCM.
import 'core/services/noti_service.dart'; // Archivo donde está configurado el handler de notificaciones en background.
import 'core/services/token_service.dart'; // Servicios para manejar y registrar tokens de FCM y FID.
import 'features/auth/login/view/login_screen.dart'; // Pantalla de login.
import 'features/home/view/home_screen.dart'; // Pantalla principal después del login.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que se haya inicializado Flutter antes de ejecutar código async.

  // Carga el archivo .env con las variables de entorno
  try {
    await dotenv.load(
      fileName: ".env",
    ); // Intenta cargar las variables de entorno desde el archivo .env.
  } catch (e) {
    debugPrint(
      "Error al cargar el archivo .env: $e",
    ); // Muestra un mensaje si ocurre un error cargando .env.
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Inicializa Firebase con la configuración para la plataforma actual.

  await initializeNotifications(); // Llama a la función para configurar las notificaciones.

  // Registra correctamente el handler de mensajes en segundo plano.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Registra el handler para notificaciones cuando la app está en segundo plano.

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Define que la app solo funcione en orientación vertical (arriba y abajo).
    runApp(const MyApp()); // Lanza la aplicación.
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key}); // Constructor de la clase MyApp.
  @override
  State<MyApp> createState() => _MyAppState(); // Crea el estado asociado a esta clase.
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState(); // Llama al initState de la clase padre.

    obtenerYEnviarTokenFCM(); // Obtiene y envía el token de Firebase Cloud Messaging.
    obtenerYEnviarFID(); // Obtiene y envía el Firebase Installation ID.
    listenTokenRefresh(); // Escucha actualizaciones del token de FCM.
    setupNotificationListeners(); // Configura listeners para notificaciones en primer plano y clics.
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título de la app (se usa en algunos dispositivos al cambiar entre apps)
      title: 'Cyptos 2.0 Demo',

      // Define el tema visual general de la app
      theme: ThemeData(
        brightness: Brightness.dark, // Establece un tema oscuro.
        primaryColor: Colors.black, // Color primario de la app.
        scaffoldBackgroundColor:
            Colors.black, // Color de fondo de las pantallas principales.
        // Tema para la AppBar (barra superior)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // Fondo negro para la AppBar.
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ), // Estilo del título.
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.white,
          ), // Estilo del texto principal.
          bodySmall: TextStyle(
            color: Colors.white70,
          ), // Estilo del texto secundario.
        ),

        // Tema visual para las tarjetas (Cards)
        cardTheme: CardTheme(
          color: Colors.grey[900],
          elevation: 4,
        ), // Estilo de las cards.
        // Tema visual para diálogos (AlertDialog, etc.)
        dialogTheme: const DialogTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ), // Título del diálogo.
          contentTextStyle: TextStyle(
            color: Colors.white70,
          ), // Contenido del diálogo.
        ),

        // Usa Material 3 (diseño más moderno)
        useMaterial3: true,
      ),
      home:
          const AuthCheck(), // Define el widget principal que se mostrará: AuthCheck.
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key}); // Constructor de AuthCheck.

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      // Escucha los cambios en el estado de autenticación del usuario.
      builder: (context, snapshot) {
        // Mientras se verifica el estado, muestra un indicador de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ), // Indicador de carga.
          );
        }

        return snapshot.hasData
            ? const HomeScreen() // Si hay un usuario autenticado, muestra la pantalla principal.
            : const LoginPage(); // Si no hay usuario autenticado, muestra la pantalla de login.
      },
    );
  }
}
