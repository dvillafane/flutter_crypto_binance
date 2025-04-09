import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_crypto_binance/blocs/crypto/crypto_event.dart';
import 'package:flutter_crypto_binance/blocs/crypto/crypto_state.dart';
import 'package:intl/intl.dart';
import '../blocs/crypto/crypto_bloc.dart';
import '../models/crypto_detail.dart';

class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  @override
  CryptoDetailListScreenState createState() => CryptoDetailListScreenState();
}

class CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final numberFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
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
        actions: [
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              if (state is CryptoLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DropdownButton<String>(
                    value: state.sortCriteria,
                    dropdownColor: Colors.grey[900],
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'priceUsd',
                        child: Text('Precio', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'cmcRank',
                        child: Text('Ranking', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CryptoBloc>().add(ChangeSortCriteria(value));
                      }
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              bool showFavorites = false;
              bool isEnabled = false;
              if (state is CryptoLoaded) {
                showFavorites = state.showFavorites;
                isEnabled = true;
              }
              return IconButton(
                icon: Icon(
                  showFavorites ? Icons.favorite : Icons.format_list_bulleted,
                  color: Colors.white,
                ),
                tooltip: showFavorites ? 'Ver todas' : 'Ver favoritas',
                onPressed: isEnabled
                    ? () => context.read<CryptoBloc>().add(ToggleFavoritesView())
                    : null,
              );
            },
          ),
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              if (state is CryptoLoaded) {
                return IconButton(
                  icon: Icon(
                    state.isWebSocketConnected ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  tooltip: state.isWebSocketConnected
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
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (context, state) {
          if (state is CryptoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CryptoLoaded) {
            return Column(
              children: [
                if (state.isUpdating) const LinearProgressIndicator(), // Mostrar solo si está actualizando
                Expanded(
                  child: _buildCryptoList(state.cryptos, state),
                ),
              ],
            );
          } else if (state is CryptoError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCryptoList(List<CryptoDetail> cryptos, CryptoLoaded state) {
    var iterable = cryptos.where(
      (c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()),
    );

    if (state.showFavorites) {
      iterable = iterable.where((c) => state.favoriteSymbols.contains(c.symbol));
    }

    final filtered = iterable.toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          state.showFavorites ? 'No tienes favoritas aún' : 'No se encontró ninguna',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final detail = filtered[i];
        final isFav = state.favoriteSymbols.contains(detail.symbol);
        return Card(
          color: Colors.grey[900],
          child: ListTile(
            leading: Image.network(
              detail.logoUrl,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
            ),
            title: Text(
              detail.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 350),
              style: TextStyle(
                color: state.priceColors[detail.symbol] ?? Colors.white70,
              ),
              child: Text('\$${numberFormat.format(detail.priceUsd)} USD'),
            ),
            trailing: IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white70,
              ),
              onPressed: () => context.read<CryptoBloc>().add(
                    ToggleFavoriteSymbol(detail.symbol),
                  ),
            ),
            onTap: () => _showCryptoDetailDialog(context, detail),
          ),
        );
      },
    );
  }

  void _showCryptoDetailDialog(BuildContext context, CryptoDetail detail) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Image.network(
              detail.logoUrl,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
            ),
            const SizedBox(width: 8),
            Text(detail.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Símbolo: ${detail.symbol}', style: const TextStyle(color: Colors.white70)),
              Text('Ranking: #${detail.cmcRank}', style: const TextStyle(color: Colors.white70)),
              Text('Precio: \$${numberFormat.format(detail.priceUsd)} USD', style: const TextStyle(color: Colors.white70)),
              Text('Volumen 24h: \$${numberFormat.format(detail.volumeUsd24Hr)} USD', style: const TextStyle(color: Colors.white70)),
              Text(
                'Cambio 24h: ${detail.percentChange24h.toStringAsFixed(2)}%',
                style: TextStyle(color: detail.percentChange24h >= 0 ? Colors.green : Colors.red),
              ),
              Text(
                'Cambio 7d: ${detail.percentChange7d.toStringAsFixed(2)}%',
                style: TextStyle(color: detail.percentChange7d >= 0 ? Colors.green : Colors.red),
              ),
              Text('Capitalización de mercado: \$${numberFormat.format(detail.marketCapUsd)} USD', style: const TextStyle(color: Colors.white70)),
              Text('Suministro circulante: ${numberFormat.format(detail.circulatingSupply)} ${detail.symbol}', style: const TextStyle(color: Colors.white70)),
              if (detail.totalSupply != null)
                Text('Suministro total: ${numberFormat.format(detail.totalSupply!)} ${detail.symbol}', style: const TextStyle(color: Colors.white70)),
              if (detail.maxSupply != null)
                Text('Suministro máximo: ${numberFormat.format(detail.maxSupply!)} ${detail.symbol}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
