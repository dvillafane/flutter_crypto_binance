// screens/crypto_detail_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto_bloc.dart';
import '../widgets/crypto_details_card.dart';
import 'crypto_detail_screen.dart';

class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  @override
  State<CryptoDetailListScreen> createState() => _CryptoDetailListScreenState();
}

class _CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar criptomoneda...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<CryptoBloc, CryptoState>(
                builder: (context, state) {
                  if (state is CryptoLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is CryptoLoaded) {
                    final filteredCryptos = state.cryptos.where((crypto) =>
                        crypto.name.toLowerCase().contains(_searchQuery) ||
                        crypto.symbol.toLowerCase().contains(_searchQuery)).toList();
                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredCryptos.length,
                      itemBuilder: (context, index) {
                        final crypto = filteredCryptos[index];
                        return CryptoDetailsCard(
                          crypto: crypto,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CryptoDetailScreen(assetId: crypto.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else if (state is CryptoError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
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
      ),
    );
  }
}
