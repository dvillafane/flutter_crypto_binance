// Importa el paquete 'dart:convert' para manejar la codificación y decodificación de JSON.
import 'dart:convert';
// Importa el paquete 'http' para realizar solicitudes HTTP.
import 'package:http/http.dart' as http;
// Importa el modelo que representa los detalles de la criptomoneda.
import '../models/crypto_detail.dart';

/// Servicio encargado de obtener detalles específicos de una criptomoneda desde la API.
class CryptoDetailService {
  // URL base de la API CoinCap para obtener detalles de criptomonedas.
  final String baseUrl = 'https://api.coincap.io/v2/assets';

  /// Método asíncrono que obtiene los detalles de una criptomoneda específica
  /// mediante su identificador (assetId).
  Future<CryptoDetail> fetchCryptoDetail(String assetId) async {
    // Construye la URL completa concatenando la base con el identificador de la criptomoneda.
    final url = Uri.parse('$baseUrl/$assetId');
    // Realiza una solicitud GET a la API para obtener los detalles.
    final response = await http.get(url);

    // Verifica si la solicitud fue exitosa (código 200).
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta JSON.
      final data = json.decode(response.body);
      // Extrae los datos específicos de la criptomoneda desde el campo 'data'.
      return CryptoDetail.fromJson(data['data']);
    } else {
      // Lanza una excepción en caso de error con el código de estado.
      throw Exception('Error al obtener detalles de la criptomoneda: ${response.statusCode}');
    }
  }
}
