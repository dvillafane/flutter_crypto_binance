// Importa la librería para manejar la conversión de datos en formato JSON.
import 'dart:convert';
// Importa el paquete http para realizar peticiones web.
import 'package:http/http.dart' as http;
// Importa el modelo Crypto, que representa la estructura de una criptomoneda.
import '../models/crypto.dart';

// Clase que se encarga de obtener datos de criptomonedas desde una API.
class CryptoService {
  // Método asíncrono que retorna una lista de objetos Crypto.
  Future<List<Crypto>> fetchCryptos() async {
    // Define la URL de la API utilizando Uri.parse para asegurar que la URL es válida.
    final url = Uri.parse('https://api.coincap.io/v2/assets');
    // Realiza una petición GET a la URL definida.
    final response = await http.get(url);

    // Verifica que la respuesta del servidor sea exitosa (código 200).
    if (response.statusCode == 200) {
      try {
        // Decodifica el cuerpo de la respuesta (JSON) a un mapa de datos.
        final data = json.decode(response.body);
        // Extrae la lista de criptomonedas que se encuentra en el campo 'data' del JSON.
        final List<dynamic> cryptoList = data['data'];
        // Mapea cada elemento de la lista a un objeto Crypto usando el constructor fromJson y retorna la lista resultante.
        return cryptoList.map((json) => Crypto.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Error al procesar los datos de criptomonedas: $e');
      }
    } else {
      // Si la respuesta no fue exitosa, lanza una excepción con un mensaje de error.
      throw Exception('Error al obtener criptomonedas: ${response.statusCode}');
    }
  }
}
