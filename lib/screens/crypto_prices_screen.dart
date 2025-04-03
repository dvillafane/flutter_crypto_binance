// Importa el paquete material de Flutter, que provee componentes de interfaz gráfica.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto_bloc.dart';
import '../models/crypto.dart';
import '../widgets/crypto_card.dart';

/// Pantalla principal para mostrar los precios de las criptomonedas con buscador
class CryptoPricesScreen extends StatefulWidget {
  const CryptoPricesScreen({super.key});

  @override
  State<CryptoPricesScreen> createState() => _CryptoPricesScreenState();
}

class _CryptoPricesScreenState extends State<CryptoPricesScreen> {
  // Variable para almacenar el texto ingresado en el campo de búsqueda
  String searchQuery = "";

  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // Liberar recursos asociados al controlador cuando el widget se elimine
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // Utiliza un Row en el title para colocar el buscador y el botón en la misma línea
        title: Row(
          children: [
            // Campo de búsqueda expandido para ocupar la mayor parte del espacio
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Buscar criptomoneda...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  // Actualizar el estado al cambiar el texto
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8), // Espacio entre el campo y el botón
            // Botón de recarga
            IconButton(
              icon: const Icon(Icons.refresh),
              color: const Color(0xFFD2E4FF),
              onPressed: () {
                context.read<CryptoBloc>().add(ReconnectWebSocket());
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BlocBuilder<CryptoBloc, CryptoState>(
              builder: (context, state) {
                if (state is CryptoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CryptoLoaded) {
                  List<Crypto> filteredCryptos = state.cryptos;
                  if (searchQuery.isNotEmpty) {
                    filteredCryptos = filteredCryptos.where((crypto) {
                      return crypto.name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          );
                    }).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredCryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = filteredCryptos[index];
                      return CryptoCard(
                        crypto: crypto,
                        priceColor:
                            state.priceColors[crypto.id] ?? Colors.white,
                        cardColor: const Color(0xFF303030), // Color de fondo
                      );
                    },
                  );
                } else if (state is CryptoError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
