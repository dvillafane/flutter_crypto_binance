// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Para manejar estados con BLoC

// Importación del BLoC que maneja las criptomonedas
import '../blocs/crypto_bloc.dart';

// Servicios que consultan la data de las criptos y los precios en tiempo real
import '../services/crypto_detail_service.dart';
import '../services/websocket_prices_service.dart';

// Pantalla que muestra la lista de detalles de criptomonedas
import 'crypto_detail_list_screen.dart';

/// Pantalla principal de la app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar superior con título estilizado
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'CRIPTOMONEDAS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Centra el título en la AppBar
      ),

      // Cuerpo de la pantalla envuelto en un BlocProvider
      body: BlocProvider(
        // Crea una instancia del CryptoBloc y lo provee a los widgets hijos
        create:
            (_) => CryptoBloc(
              cryptoService:
                  CryptoDetailService(), // Servicio HTTP para obtener detalles de criptos
              pricesService:
                  WebSocketPricesService(), // Servicio WebSocket para precios en tiempo real
            ),
        child:
            CryptoDetailListScreen(), // Widget hijo que consume el BLoC y muestra la lista
      ),
    );
  }
}
