// screens/crypto_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../blocs/crypto_detail_bloc.dart';
import '../services/crypto_detail_service.dart';

class CryptoDetailScreen extends StatelessWidget {
  final String assetId;

  const CryptoDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CryptoDetailBloc(detailService: CryptoDetailService())
        ..add(LoadCryptoDetail(assetId: assetId)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<CryptoDetailBloc, CryptoDetailState>(
          builder: (context, state) {
            if (state is CryptoDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CryptoDetailLoaded) {
              final detail = state.detail;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        detail.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Image.network(detail.logoUrl, width: 100, height: 100),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Símbolo', detail.symbol, LucideIcons.hash),
                              _buildInfoRow('Rank', detail.rank.toString(), LucideIcons.star),
                              _buildInfoRow('Suministro', detail.supply.toString(), LucideIcons.database),
                              if (detail.maxSupply != null)
                                _buildInfoRow('Suministro Máximo', detail.maxSupply.toString(), LucideIcons.layers),
                              _buildInfoRow('Market Cap', '\$${detail.marketCapUsd.toStringAsFixed(2)}', LucideIcons.dollarSign),
                              _buildInfoRow('Volumen 24h', '\$${detail.volumeUsd24Hr.toStringAsFixed(2)}', LucideIcons.pieChart),
                              _buildInfoRow('Precio', '\$${detail.priceUsd.toStringAsFixed(2)}', LucideIcons.trendingUp),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is CryptoDetailError) {
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
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: ",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
