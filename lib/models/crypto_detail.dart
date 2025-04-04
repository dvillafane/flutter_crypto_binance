import 'package:equatable/equatable.dart';

class CryptoDetail extends Equatable {
  final String symbol;        // Símbolo visible (ej. "BTC")
  final String tradingPair;   // Par completo para la API (ej. "BTCUSDT")
  final String name;          // Nombre simplificado de la criptomoneda
  final double priceUsd;      // Precio actual en USD
  final double volumeUsd24Hr; // Volumen de 24 horas en USD
  final String logoUrl;       // URL del logo

  const CryptoDetail({
    required this.symbol,
    required this.tradingPair,
    required this.name,
    required this.priceUsd,
    required this.volumeUsd24Hr,
    required this.logoUrl,
  });

  // Constructor desde JSON de Binance
  factory CryptoDetail.fromJson(Map<String, dynamic> json, String tradingPair) {
    final baseSymbol = tradingPair.replaceAll('USDT', '');
    return CryptoDetail(
      symbol: baseSymbol,
      tradingPair: tradingPair,
      name: baseSymbol, // Aquí podrías mejorar con un nombre más descriptivo si lo tienes
      priceUsd: double.tryParse(json['lastPrice']) ?? 0,
      volumeUsd24Hr: double.tryParse(json['quoteVolume']) ?? 0,
      logoUrl: 'https://assets.coincap.io/assets/icons/${baseSymbol.toLowerCase()}@2x.png',
    );
  }

  // Constructor desde Firestore
  factory CryptoDetail.fromFirestore(Map<String, dynamic> data) {
    return CryptoDetail(
      symbol: data['symbol'] ?? '',
      tradingPair: data['tradingPair'] ?? '',
      name: data['name'] ?? '',
      priceUsd: (data['priceUsd'] as num?)?.toDouble() ?? 0,
      volumeUsd24Hr: (data['volumeUsd24Hr'] as num?)?.toDouble() ?? 0,
      logoUrl: data['logoUrl'] ?? '',
    );
  }

  @override
  List<Object?> get props => [symbol, tradingPair, name, priceUsd, volumeUsd24Hr, logoUrl];
}