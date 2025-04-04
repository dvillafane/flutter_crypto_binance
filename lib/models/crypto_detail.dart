import 'package:equatable/equatable.dart';

class CryptoDetail extends Equatable {
  final String symbol;        // Símbolo visible (ej. "BTC")
  final String name;          // Nombre completo (ej. "Bitcoin")
  final double priceUsd;      // Precio actual en USD
  final double volumeUsd24Hr; // Volumen de 24 horas en USD
  final String logoUrl;       // URL del logo

  const CryptoDetail({
    required this.symbol,
    required this.name,
    required this.priceUsd,
    required this.volumeUsd24Hr,
    required this.logoUrl,
  });

  // Constructor desde Firestore
  factory CryptoDetail.fromFirestore(Map<String, dynamic> data) {
    return CryptoDetail(
      symbol: data['symbol'] ?? '',
      name: data['name'] ?? '',
      priceUsd: (data['priceUsd'] as num?)?.toDouble() ?? 0,
      volumeUsd24Hr: (data['volumeUsd24Hr'] as num?)?.toDouble() ?? 0,
      logoUrl: data['logoUrl'] ?? '',
    );
  }

  @override
  List<Object?> get props => [symbol, name, priceUsd, volumeUsd24Hr, logoUrl];
}