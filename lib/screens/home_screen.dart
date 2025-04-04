// Importa el paquete material de Flutter para componentes visuales.
import 'package:flutter/material.dart';
// Importa la pantalla de detalles de criptomonedas.
import 'package:flutter_crypto_binance/screens/crypto_detail_list_screen.dart';
// Importa la pantalla de precios de criptomonedas.
import 'crypto_prices_screen.dart';

/// Pantalla principal de la aplicación que muestra un tab bar para alternar entre 
/// la lista de precios de criptomonedas y la lista de detalles de criptomonedas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Define la cantidad de pestañas (2 en este caso: "Precios" y "Detalles").
      length: 2,
      child: Scaffold(
        // Barra de navegación superior.
        appBar: AppBar(
          backgroundColor: Colors.black, // Fondo negro para el AppBar.
          title: const Text(
            'CRIPTOMONEDAS', // Título central de la aplicación.
            style: TextStyle(
              color: Colors.white, // Texto en color blanco.
              fontSize: 24, // Tamaño grande para resaltar el título.
              fontWeight: FontWeight.bold, // Texto en negrita.
            ),
          ),
          centerTitle: true, // Centra el título en la barra superior.
          // Barra de pestañas en la parte inferior del AppBar.
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent, // Color del indicador de la pestaña activa.
            tabs: [
              // Pestaña para visualizar los precios de criptomonedas.
              Tab(text: "Precios"),
              // Pestaña para visualizar la lista detallada de criptomonedas.
              Tab(text: "Detalles"),
            ],
          ),
        ),
        // Cuerpo de la pantalla que muestra las vistas correspondientes a cada pestaña.
        body: TabBarView(
          children: [
            // Muestra la pantalla de precios cuando la pestaña "Precios" está activa.
            const CryptoPricesScreen(),
            // Muestra la pantalla de detalles cuando la pestaña "Detalles" está activa.
            CryptoDetailListScreen(),
          ],
        ),
      ),
    );
  }
}
