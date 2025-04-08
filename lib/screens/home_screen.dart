// Importaciones necesarias
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto/crypto_bloc.dart';
import '../services/crypto_detail_service.dart';
import '../services/websocket_prices_service.dart';
import 'crypto_detail_list_screen.dart';
import 'profile_screen.dart';

// Definición de la pantalla principal que contendrá la navegación inferior
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Creación del estado asociado a HomeScreen
  @override
  HomeScreenState createState() => HomeScreenState();
}

// Estado de la pantalla principal donde se gestiona la navegación y los widgets mostrados
class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex =
      0; // Índice de la pantalla actualmente seleccionada (0: Home, 1: Perfil)

  // Lista de pantallas a mostrar basada en la opción seleccionada en la barra de navegación inferior
  final List<Widget> _screens = [
    // Se utiliza un BlocProvider para inyectar la lógica de negocio CryptoBloc en la pantalla de criptomonedas
    BlocProvider(
      create:
          (context) => CryptoBloc(
            userId:
                FirebaseAuth
                    .instance
                    .currentUser!
                    .uid, // Se utiliza el UID del usuario autenticado en Firebase
            cryptoService:
                CryptoDetailService(), // Servicio para obtener los detalles de criptomonedas
            pricesService:
                WebSocketPricesService(), // Servicio para recibir actualizaciones en tiempo real de precios por WebSocket
          ),
      child:
          const CryptoDetailListScreen(), // Pantalla que muestra la lista de criptomonedas
    ),
    const ProfileScreen(), // Pantalla de perfil del usuario
  ];

  // Método para actualizar la pantalla seleccionada mediante la barra de navegación
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Actualiza el índice al que fue tocado
    });
  }

  // Construcción de la interfaz del widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _screens[_selectedIndex], // Muestra la pantalla correspondiente al índice seleccionado
      // Barra de navegación inferior para cambiar entre pantallas
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            Colors.black, // Color de fondo de la barra de navegación
        selectedItemColor: Colors.white, // Color de los ítems seleccionados
        unselectedItemColor: Colors.grey, // Color de los ítems no seleccionados
        currentIndex: _selectedIndex, // Índice actualmente seleccionado
        onTap:
            _onItemTapped, // Método que se invoca al tocar un ítem en la barra
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Ícono para la pantalla de inicio
            label: 'Home', // Etiqueta del ítem
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Ícono para la pantalla de perfil
            label: 'Perfil', // Etiqueta del ítem
          ),
        ],
      ),
    );
  }
}
