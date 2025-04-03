import 'package:equatable/equatable.dart';

class CryptoDetail extends Equatable {
  final String symbol; // Símbolo visible (ej. "BTC")
  final String tradingPair; // Par completo para la API (ej. "BTCUSDT")
  final String name; // Nombre de la criptomoneda
  final double priceUsd; // Precio actual en USD
  final double volumeUsd24Hr; // Volumen de 24 horas en USD
  final String logoUrl; // URL del logo

  const CryptoDetail({
    required this.symbol,
    required this.tradingPair,
    required this.name,
    required this.priceUsd,
    required this.volumeUsd24Hr,
    required this.logoUrl,
  });

  factory CryptoDetail.fromJson(Map<String, dynamic> json, String tradingPair) {
    final baseSymbol = tradingPair.replaceAll(
      'USDT',
      '',
    ); // Extrae "BTC" de "BTCUSDT"
    return CryptoDetail(
      symbol: baseSymbol, // Solo "BTC"
      tradingPair: tradingPair, // "BTCUSDT" para uso interno
      name: baseSymbol, // Usamos el símbolo como nombre por simplicidad
      priceUsd: double.tryParse(json['lastPrice']) ?? 0,
      volumeUsd24Hr: double.tryParse(json['quoteVolume']) ?? 0,
      logoUrl:
          'https://assets.coincap.io/assets/icons/${baseSymbol.toLowerCase()}@2x.png',
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    tradingPair,
    name,
    priceUsd,
    volumeUsd24Hr,
    logoUrl,
  ];
}
