import 'package:equatable/equatable.dart';

// Definición del modelo de datos CryptoDetail
class CryptoDetail extends Equatable {
  final String id; // ID único de CoinMarketCap
  final String name; // Nombre de la criptomoneda
  final String symbol; // Símbolo (ej. BTC)
  final int cmcRank; // Posición en el ranking
  final double priceUsd; // Precio en USD
  final double volumeUsd24Hr; // Volumen de comercio en 24 horas
  final double percentChange24h; // Cambio porcentual en 24 horas
  final double percentChange7d; // Cambio porcentual en 7 días
  final double marketCapUsd; // Capitalización de mercado
  final double circulatingSupply; // Suministro circulante
  final double? totalSupply; // Suministro total (puede ser null)
  final double? maxSupply; // Suministro máximo (puede ser null)
  final String logoUrl; // URL del logo

  const CryptoDetail({
    required this.id,
    required this.name,
    required this.symbol,
    required this.cmcRank,
    required this.priceUsd,
    required this.volumeUsd24Hr,
    required this.percentChange24h,
    required this.percentChange7d,
    required this.marketCapUsd,
    required this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    required this.logoUrl,
  });

  // Constructor de fábrica que crea una instancia a partir de un mapa
  factory CryptoDetail.fromFirestore(Map<String, dynamic> data) {
    return CryptoDetail(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      symbol: data['symbol'] ?? '',
      cmcRank: data['cmcRank'] ?? 0,
      priceUsd: (data['priceUsd'] as num?)?.toDouble() ?? 0,
      volumeUsd24Hr: (data['volumeUsd24Hr'] as num?)?.toDouble() ?? 0,
      percentChange24h: (data['percentChange24h'] as num?)?.toDouble() ?? 0,
      percentChange7d: (data['percentChange7d'] as num?)?.toDouble() ?? 0,
      marketCapUsd: (data['marketCapUsd'] as num?)?.toDouble() ?? 0,
      circulatingSupply: (data['circulatingSupply'] as num?)?.toDouble() ?? 0,
      totalSupply: (data['totalSupply'] as num?)?.toDouble(),
      maxSupply: (data['maxSupply'] as num?)?.toDouble(),
      logoUrl: data['logoUrl'] ?? '',
    );
  }

  // Sobrescribimos `props` de Equatable para permitir comparaciones de objetos por valor
  @override
  List<Object?> get props => [
    id,
    name,
    symbol,
    cmcRank,
    priceUsd,
    volumeUsd24Hr,
    percentChange24h,
    percentChange7d,
    marketCapUsd,
    circulatingSupply,
    totalSupply,
    maxSupply,
    logoUrl,
  ];
}
