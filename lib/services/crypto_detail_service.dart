// Importa el paquete 'dart:convert' para manejar la codificación y decodificación de JSON.
import 'dart:convert';
// Importa el paquete 'http' para realizar solicitudes HTTP.
import 'package:http/http.dart' as http;
// Importa el modelo que representa los detalles de la criptomoneda.
import '../models/crypto_detail.dart';

/// Servicio encargado de obtener detalles específicos de una criptomoneda desde la API.
class CryptoDetailService {
  final String baseUrl = 'https://api.binance.com';

  /// Método asíncrono que obtiene los detalles de una criptomoneda específica
  /// mediante su identificador (assetId).
  Future<CryptoDetail> fetchCryptoDetail(String assetId) async {
    final tradingPair =
        '${assetId.toUpperCase()}USDT'; // Par completo: "BTCUSDT"
    final url = Uri.parse('$baseUrl/api/v3/ticker/24hr?symbol=$tradingPair');
    final response = await http.get(url);

    // Verifica si la solicitud fue exitosa (código 200).
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta JSON.
      final data = json.decode(response.body);
      return CryptoDetail.fromJson(data, tradingPair);
    } else {
      // Lanza una excepción en caso de error con el código de estado.
      throw Exception(
        'Error al obtener detalles de la criptomoneda: ${response.statusCode}',
      );
    }
  }
}
