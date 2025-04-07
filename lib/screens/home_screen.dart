// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Para manejar estados con BLoC
import '../blocs/crypto_bloc.dart';
import '../services/crypto_detail_service.dart';
import '../services/websocket_prices_service.dart';
import 'crypto_detail_list_screen.dart';

/// Pantalla principal de la app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar superior con logo en lugar de texto
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.asset(
          'assets/icon/app_icon.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true, // Centra el logo en la AppBar
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
            const CryptoDetailListScreen(), // Widget hijo que consume el BLoC y muestra la lista
      ),
    );
  }
}
