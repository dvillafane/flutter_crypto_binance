// Importamos Equatable para poder comparar instancias de Crypto fácilmente (útil para BLoC, test, etc.)
import 'package:equatable/equatable.dart';

// Clase que representa una criptomoneda básica
class Crypto extends Equatable {
  // Atributos de la criptomoneda
  final String id; // ID único (por ejemplo: "bitcoin")
  final String name; // Nombre completo (ej: "Bitcoin")
  final String symbol; // Símbolo (ej: "BTC")
  final double price; // Precio actual en USD
  final String logoUrl; // URL del logo generado dinámicamente

  // Constructor constante con todos los campos requeridos
  const Crypto({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.logoUrl,
  });

  // Método de fábrica que crea una instancia de Crypto a partir de un JSON
  factory Crypto.fromJson(Map<String, dynamic> json) {
    return Crypto(
      id: json['id'], // ID único del activo
      name: json['name'], // Nombre del activo
      symbol: json['symbol'].toUpperCase(), // Símbolo en mayúsculas (ej. BTC)
      price:
          double.tryParse(json['priceUsd'].toString()) ??
          0, // Convierte el precio a double de forma segura
      logoUrl:
          'https://assets.coincap.io/assets/icons/${json['symbol'].toLowerCase()}@2x.png',
      // Genera automáticamente la URL del ícono usando el símbolo en minúsculas
      // Ejemplo: para BTC → https://assets.coincap.io/assets/icons/btc@2x.png
    );
  }

  // Sobrescribimos props para que Equatable sepa qué campos usar en la comparación
  @override
  List<Object> get props => [id, name, symbol, price, logoUrl];
}
