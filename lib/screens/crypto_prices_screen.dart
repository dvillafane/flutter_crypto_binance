import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto_bloc.dart';
import '../models/crypto_detail.dart'; // Importamos CryptoDetail en lugar de Crypto
import '../widgets/crypto_card.dart';

class CryptoPricesScreen extends StatefulWidget {
  const CryptoPricesScreen({super.key});

  @override
  State<CryptoPricesScreen> createState() => _CryptoPricesScreenState();
}

class _CryptoPricesScreenState extends State<CryptoPricesScreen> {
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
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
                      color: const Color(0xFFD2E4FF),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BlocBuilder<CryptoBloc, CryptoState>(
              builder: (context, state) {
                if (state is CryptoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CryptoLoaded) {
                  // Cambiamos List<Crypto> a List<CryptoDetail>
                  List<CryptoDetail> filteredCryptos = state.cryptos;
                  if (searchQuery.isNotEmpty) {
                    filteredCryptos = filteredCryptos.where((crypto) {
                      return crypto.name.toLowerCase().contains(searchQuery.toLowerCase());
                    }).toList();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredCryptos.length,
                    itemBuilder: (context, index) {
                      final crypto = filteredCryptos[index];
                      return CryptoCard(
                        crypto: crypto, // Ahora es CryptoDetail
                        priceColor: state.priceColors[crypto.symbol] ?? Colors.white,
                        cardColor: const Color(0xFF303030),
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