// Importamos la librería Equatable para facilitar la comparación entre objetos (útil en BLoC y tests)
import 'package:equatable/equatable.dart';

// Definición del modelo de datos CryptoDetail
class CryptoDetail extends Equatable {
  // Atributos de la criptomoneda
  final String symbol; // Símbolo visible (ejemplo: "BTC" para Bitcoin)
  final String name; // Nombre completo de la criptomoneda (ejemplo: "Bitcoin")
  final double priceUsd; // Precio actual en dólares estadounidenses
  final double
  volumeUsd24Hr; // Volumen de transacciones en las últimas 24 horas en USD
  final String logoUrl; // URL de la imagen del logo de la criptomoneda

  // Constructor constante con todos los campos requeridos
  const CryptoDetail({
    required this.symbol,
    required this.name,
    required this.priceUsd,
    required this.volumeUsd24Hr,
    required this.logoUrl,
  });

  // Constructor de fábrica que crea una instancia a partir de un mapa (por ejemplo, desde Firestore)
  factory CryptoDetail.fromFirestore(Map<String, dynamic> data) {
    return CryptoDetail(
      symbol: data['symbol'] ?? '', // Si no existe, usa string vacío
      name: data['name'] ?? '',
      priceUsd:
          (data['priceUsd'] as num?)?.toDouble() ??
          0, // Conversión segura a double
      volumeUsd24Hr: (data['volumeUsd24Hr'] as num?)?.toDouble() ?? 0,
      logoUrl: data['logoUrl'] ?? '',
    );
  }

  // Sobrescribimos `props` de Equatable para permitir comparaciones de objetos por valor
  @override
  List<Object?> get props => [symbol, name, priceUsd, volumeUsd24Hr, logoUrl];
}
