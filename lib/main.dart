// Importa el paquete material de Flutter, que provee componentes de interfaz gráfica.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Importa la pantalla principal de la aplicación.
import 'screens/home_screen.dart';
import 'blocs/crypto_bloc.dart';
import 'services/crypto_service.dart';
import 'services/websocket_prices_service.dart';

// Función principal de la aplicación, el punto de entrada.
// Ejecuta la aplicación pasando el widget MyApp.
void main() => runApp(MyApp());

/// Widget principal de la aplicación, de tipo StatelessWidget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Método build que construye la interfaz de usuario del widget.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Proporciona el BLoC de criptomonedas al árbol completo de la aplicación
      create: (_) => CryptoBloc(
        cryptoService: CryptoService(),
        pricesService: WebSocketPricesService(),
      ),
      child: MaterialApp(
        // Título de la aplicación, utilizado en algunos contextos del sistema.
        title: 'CoinCap API 2.0 Demo',
        // Configuración del tema visual de la aplicación.
        theme: ThemeData(
          // Define una paleta de colores basada en un color semilla.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          // Activa el uso de Material Design 3.
          useMaterial3: true,
        ),
        // Define la pantalla principal que se muestra al iniciar la aplicación.
        home: HomeScreen(),
      ),
    );
  }
}
