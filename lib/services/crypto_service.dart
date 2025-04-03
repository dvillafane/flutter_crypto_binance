// Importa la librería para trabajar con JSON
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto.dart';

/// Clase que maneja la lógica para obtener información de criptomonedas
class CryptoService {
  // URL base de la API de Binance
  final String baseUrl = 'https://api.binance.com';

  /// Método asíncrono que obtiene la lista de criptomonedas
  Future<List<Crypto>> fetchCryptos() async {
    // Construir la URL para obtener la información del exchange
    // Esto incluye detalles de todos los símbolos disponibles en la plataforma
    final exchangeInfoUrl = Uri.parse('$baseUrl/api/v3/exchangeInfo');
    // Realiza la petición HTTP GET a la URL de información del exchange
    final exchangeInfoResponse = await http.get(exchangeInfoUrl);

    // Verificar si la respuesta fue exitosa (código 200)
    if (exchangeInfoResponse.statusCode != 200) {
      // En caso de error, se lanza una excepción con el código de error
      throw Exception(
        'Error al obtener información de exchange: ${exchangeInfoResponse.statusCode}',
      );
    }

    // Decodificar la respuesta JSON a un mapa de datos
    final exchangeInfoData = json.decode(exchangeInfoResponse.body);
    // Extraer la lista de símbolos de la respuesta
    final List<dynamic> symbols = exchangeInfoData['symbols'];

    // Filtrar los símbolos para obtener únicamente aquellos que cotizan en USDT
    final usdtSymbols =
        symbols
            .where((symbol) => symbol['quoteAsset'] == 'USDT')
            .map((symbol) => symbol['symbol'])
            .toList();

    // Construir la URL para obtener los precios actuales de las criptomonedas
    final priceUrl = Uri.parse('$baseUrl/api/v3/ticker/price');
    // Realiza la petición HTTP GET a la URL de precios
    final priceResponse = await http.get(priceUrl);

    // Verificar si la respuesta fue exitosa (código 200)
    if (priceResponse.statusCode != 200) {
      // En caso de error, se lanza una excepción con el código de error
      throw Exception('Error al obtener precios: ${priceResponse.statusCode}');
    }

    // Decodificar la respuesta JSON a una lista de datos
    final List<dynamic> priceData = json.decode(priceResponse.body);

    // Crear un mapa de precios para acceder fácilmente al precio de cada símbolo
    final Map<String, double> priceMap = {
      for (var item in priceData)
        item['symbol']: double.tryParse(item['price']) ?? 0,
    };

    // Inicializar una lista vacía que contendrá las instancias de Crypto
    final List<Crypto> cryptos = [];
    // Iterar sobre cada símbolo que cotiza en USDT
    for (var symbol in usdtSymbols) {
      // Extraer el activo base eliminando 'USDT' del símbolo
      // Ejemplo: "BTCUSDT" se transforma en "BTC"
      final baseAsset = symbol.replaceAll('USDT', '');
      // Obtener el precio correspondiente del mapa de precios
      final price = priceMap[symbol] ?? 0;
      // Si se encontró un precio mayor a 0, se crea una instancia de Crypto
      if (price > 0) {
        cryptos.add(
          Crypto(
            id:
                baseAsset
                    .toLowerCase(), // Convertir a minúsculas, ejemplo: "btc"
            name: baseAsset, // Se utiliza el símbolo como nombre
            symbol: baseAsset, // Se utiliza el símbolo
            price: price, // Precio obtenido
            logoUrl: '', // Se omite el logo o se podría usar un placeholder
          ),
        );
      }
    }

    // Retorna la lista de criptomonedas obtenida y procesada
    return cryptos;
  }
}
