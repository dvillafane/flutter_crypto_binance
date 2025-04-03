// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_crypto_binance/screens/crypto_detail_list_screen.dart';
import 'crypto_prices_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Pestañas: Precios y Detalles
      child: Scaffold(
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
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: "Precios"),
              Tab(text: "Detalles"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CryptoPricesScreen(),
            CryptoDetailListScreen(),
          ],
        ),
      ),
    );
  }
}
