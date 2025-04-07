// Importamos los paquetes necesarios
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/crypto_bloc.dart';
import '../models/crypto_detail.dart';

// Pantalla que muestra la lista de criptomonedas con sus detalles
class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  @override
  CryptoDetailListScreenState createState() => CryptoDetailListScreenState();
}

class CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  String searchQuery = ""; // Almacena el texto del campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  final numberFormat = NumberFormat(
    '#,##0.00',
    'en_US',
  ); // Para formatear los números

  @override
  void dispose() {
    _searchController.dispose(); // Liberamos recursos del controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Título "CRYPTOS" alineado a la izquierda
        title: const Text(
          'CRYPTOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 16,
        // Campo de búsqueda en la parte inferior del AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
        // Iconos de acciones: alternar favoritas y activar/desactivar WebSocket
        actions: [
          // Botón para alternar entre ver todas o solo favoritas
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              if (state is CryptoLoaded) {
                return IconButton(
                  icon: Icon(
                    state.showFavorites
                        ? Icons.favorite
                        : Icons.format_list_bulleted,
                    color: Colors.white,
                  ),
                  tooltip: state.showFavorites ? 'Ver todas' : 'Ver favoritas',
                  onPressed:
                      () =>
                          context.read<CryptoBloc>().add(ToggleFavoritesView()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Botón para activar/desactivar actualizaciones por WebSocket
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              if (state is CryptoLoaded) {
                return IconButton(
                  icon: Icon(
                    state.isWebSocketConnected ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  tooltip:
                      state.isWebSocketConnected
                          ? 'Detener actualizaciones'
                          : 'Reanudar actualizaciones',
                  onPressed: () {
                    if (state.isWebSocketConnected) {
                      context.read<CryptoBloc>().add(DisconnectWebSocket());
                    } else {
                      context.read<CryptoBloc>().add(ConnectWebSocket());
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      // Cuerpo de la pantalla
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (context, state) {
          if (state is CryptoLoading) {
            // Muestra un indicador de carga mientras se obtienen los datos
            return const Center(child: CircularProgressIndicator());
          } else if (state is CryptoLoaded) {
            // Filtro de búsqueda por nombre
            var iterable = state.cryptos.where(
              (c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()),
            );

            // Si está activado el modo favoritos, filtramos también por favoritos
            if (state.showFavorites) {
              iterable = iterable.where(
                (c) => state.favoriteSymbols.contains(c.symbol),
              );
            }

            final filtered = iterable.toList();

            // Si no hay criptos para mostrar
            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  state.showFavorites
                      ? 'No tienes favoritas aún'
                      : 'No se encontró ninguna',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }

            // Lista de criptomonedas
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final detail = filtered[i];
                final isFav = state.favoriteSymbols.contains(detail.symbol);
                return Card(
                  color: Colors.grey[900],
                  child: ListTile(
                    // Icono/logo de la criptomoneda
                    leading: Image.network(
                      detail.logoUrl,
                      width: 32,
                      height: 32,
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(Icons.error, color: Colors.red),
                    ),
                    // Nombre de la cripto
                    title: Text(
                      detail.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    // Precio con animación de cambio de color según su variación
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
                    // Botón para marcar como favorita
                    trailing: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white70,
                      ),
                      onPressed:
                          () => context.read<CryptoBloc>().add(
                            ToggleFavoriteSymbol(detail.symbol),
                          ),
                    ),
                    // Al tocar, muestra un diálogo con más detalles
                    onTap: () => _showCryptoDetailDialog(context, detail),
                  ),
                );
              },
            );
          } else if (state is CryptoError) {
            // Si hubo un error, lo mostramos
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink(); // Por defecto, no muestra nada
        },
      ),
    );
  }

  // Muestra un AlertDialog con información detallada de la criptomoneda
  void _showCryptoDetailDialog(BuildContext context, CryptoDetail detail) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                Image.network(
                  detail.logoUrl,
                  width: 32,
                  height: 32,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.error, color: Colors.red),
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
          ),
    );
  }
}
