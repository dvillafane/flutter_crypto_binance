import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto_bloc.dart';
import '../models/crypto_detail.dart';

class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  @override
  _CryptoDetailListScreenState createState() => _CryptoDetailListScreenState();
}

class _CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<CryptoBloc, CryptoState>(
              builder: (context, state) {
                if (state is CryptoLoaded) {
                  return IconButton(
                    icon: Icon(
                      state.isWebSocketConnected ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
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
      ),
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (context, state) {
          if (state is CryptoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CryptoLoaded) {
            List<CryptoDetail> filteredCryptos = state.cryptos;
            if (searchQuery.isNotEmpty) {
              filteredCryptos = filteredCryptos.where((crypto) {
                return crypto.name.toLowerCase().contains(searchQuery.toLowerCase());
              }).toList();
            }
            return ListView.builder(
              itemCount: filteredCryptos.length,
              itemBuilder: (context, index) {
                final detail = filteredCryptos[index];
                return Card(
                  child: ListTile(
                    leading: Image.network(
                      detail.logoUrl,
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                    ),
                    title: Text(detail.name),
                    subtitle: Text(
                      '\$${detail.priceUsd.toStringAsFixed(2)} USD',
                      style: TextStyle(
                        color: state.priceColors[detail.symbol] ?? Colors.black,
                      ),
                    ),
                    onTap: () => _showCryptoDetailDialog(context, detail),
                  ),
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
    );
  }

  void _showCryptoDetailDialog(BuildContext context, CryptoDetail detail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.network(
                detail.logoUrl,
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => const Icon(Icons.error),
              ),
              const SizedBox(width: 8),
              Text(detail.name),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Símbolo: ${detail.symbol}'),
              Text('Precio: \$${detail.priceUsd.toStringAsFixed(2)} USD'),
              Text('Volumen 24h: \$${detail.volumeUsd24Hr.toStringAsFixed(2)} USD'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}