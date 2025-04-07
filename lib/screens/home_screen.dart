// Importaciones necesarias
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Para manejar estados con BLoC
import '../blocs/crypto/crypto_bloc.dart';
import '../services/crypto_detail_service.dart';
import '../services/websocket_prices_service.dart';
import 'crypto_detail_list_screen.dart';
import 'auth_screen/login_screen.dart';

/// Pantalla principal de la app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Estructura básica de la pantalla
      appBar: AppBar(
        backgroundColor: Colors.black, // Color de fondo negro para la AppBar
        title: Image.asset(
          'assets/icon/app_icon.png', // Logo de la aplicación en la AppBar
          width: 40,
          height: 40,
          fit: BoxFit.contain, // Ajuste del logo para que no se deforme
        ),
        centerTitle: true, // Centra el logo en la AppBar
      ),
      drawer: Drawer(
        // Menú lateral (Drawer)
        child: Container(
          color: Colors.grey[900], // Color de fondo oscuro para el menú
          child: ListView(
            padding:
                EdgeInsets
                    .zero, // Sin padding para que los elementos inicien desde arriba
            children: <Widget>[
              const DrawerHeader(
                // Encabezado del menú lateral
                decoration: BoxDecoration(
                  color: Colors.black, // Fondo negro para el encabezado
                ),
                child: Text(
                  'Menú',
                  style: TextStyle(
                    color: Colors.white, // Texto blanco
                    fontSize: 24, // Tamaño del texto
                  ),
                ),
              ),
              ListTile(
                // Opción para cerrar sesión
                leading: const Icon(
                  Icons.exit_to_app,
                  color: Colors.white,
                ), // Ícono de salir
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.white), // Texto blanco
                ),
                onTap: () {
                  FirebaseAuth.instance.signOut(); // Cierra sesión con Firebase
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ), // Redirige a la pantalla de login
                    (route) =>
                        false, // Elimina todas las rutas anteriores para evitar volver atrás
                  ); // Redirige a la pantalla de login
                },
              ),
            ],
          ),
        ),
      ),
      // Cuerpo de la pantalla envuelto en un BlocProvider
      body: BlocProvider(
        // Crea una instancia del CryptoBloc y lo provee a los widgets hijos
        create:
            (_) => CryptoBloc(
              userId: FirebaseAuth.instance.currentUser!.uid,
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
