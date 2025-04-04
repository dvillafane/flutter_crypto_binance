// Importamos los paquetes necesarios
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Importación agregada
import '../blocs/crypto_bloc.dart';
import '../models/crypto_detail.dart';

// Pantalla de lista de detalles de criptomonedas
class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  @override
  CryptoDetailListScreenState createState() => CryptoDetailListScreenState();
}

class CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  String searchQuery = ""; // Variable para guardar el texto de búsqueda
  final TextEditingController _searchController =
      TextEditingController(); // Controlador del TextField
  final numberFormat = NumberFormat(
    '#,##0.00',
    'en_US',
  ); // Formateador agregado

  @override
  void dispose() {
    _searchController.dispose(); // Liberamos el controlador cuando ya no se use
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              // Campo de búsqueda
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Buscar criptomoneda...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    // Actualiza el estado cuando el usuario escribe
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Botón para conectar o desconectar el WebSocket
              BlocBuilder<CryptoBloc, CryptoState>(
                builder: (context, state) {
                  if (state is CryptoLoaded) {
                    return IconButton(
                      icon: Icon(
                        state.isWebSocketConnected
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Alternar entre conexión y desconexión
                        if (state.isWebSocketConnected) {
                          context.read<CryptoBloc>().add(DisconnectWebSocket());
                        } else {
                          context.read<CryptoBloc>().add(ConnectWebSocket());
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink(); // No muestra nada si el estado no es el correcto
                },
              ),
            ],
          ),
        ),
      ),
      // Cuerpo de la pantalla: Lista de criptomonedas
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (context, state) {
          if (state is CryptoLoading) {
            // Muestra un indicador de carga mientras se obtienen los datos
            return const Center(child: CircularProgressIndicator());
          } else if (state is CryptoLoaded) {
            // Filtramos la lista según el texto de búsqueda
            List<CryptoDetail> filteredCryptos = state.cryptos;
            if (searchQuery.isNotEmpty) {
              filteredCryptos =
                  filteredCryptos.where((crypto) {
                    return crypto.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );
                  }).toList();
            }
            // Lista de criptomonedas renderizadas
            return ListView.builder(
              itemCount: filteredCryptos.length,
              itemBuilder: (context, index) {
                final detail = filteredCryptos[index];
                return Card(
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: Image.network(
                      detail.logoUrl,
                      width: 32,
                      height: 32,
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(Icons.error, color: Colors.red),
                    ),
                    title: Text(
                      detail.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 350),
                      style: TextStyle(
                        color:
                            state.priceColors[detail.symbol] ?? Colors.white70,
                      ),
                      child: Text(
                        '\$${numberFormat.format(detail.priceUsd)} USD',
                      ),
                    ),
                    onTap:
                        () => _showCryptoDetailDialog(
                          context,
                          detail,
                        ), // Al tocar muestra los detalles
                  ),
                );
              },
            );
          } else if (state is CryptoError) {
            // Muestra un mensaje de error si ocurre uno
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          // Si el estado no es ninguno de los anteriores, no muestra nada
          return Container();
        },
      ),
    );
  }

  // Función que muestra un diálogo con detalles de la criptomoneda
  void _showCryptoDetailDialog(BuildContext context, CryptoDetail detail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              Image.network(
                detail.logoUrl,
                width: 32,
                height: 32,
                errorBuilder:
                    (_, __, ___) => const Icon(Icons.error, color: Colors.red),
              ),
              const SizedBox(width: 8),
              Text(detail.name, style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Símbolo: ${detail.symbol}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Precio: \$${numberFormat.format(detail.priceUsd)} USD',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Volumen 24h: \$${numberFormat.format(detail.volumeUsd24Hr)} USD',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
