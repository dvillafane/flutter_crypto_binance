// Importaciones necesarias
import 'dart:convert'; // Para decodificar la respuesta JSON
import 'package:http/http.dart'
    as http; // Cliente HTTP para hacer solicitudes a la API
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore para almacenamiento en la nube
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Para acceder a variables de entorno
import '../models/crypto_detail.dart'; // Modelo de datos

// Servicio para obtener detalles de criptomonedas
class CryptoDetailService {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // URL base de la API de CoinMarketCap
  final String coinMarketCapBaseUrl = 'https://pro-api.coinmarketcap.com';

  // Clave API obtenida desde las variables de entorno
  final String apiKey =
      dotenv.env['API_KEY'] ?? 'default_key'; // Fallback si no se encuentra

  /// Método para obtener las 100 criptomonedas principales desde CoinMarketCap
  Future<List<CryptoDetail>> fetchTop100CryptoDetails() async {
    // Encabezado con la API key
    final headers = {'X-CMC_PRO_API_KEY': apiKey};
    // Construye la URL con parámetros para obtener el top 100
    final listingsUrl = Uri.parse(
      '$coinMarketCapBaseUrl/v1/cryptocurrency/listings/latest?start=1&limit=100&convert=USD',
    );
    // Solicitud GET a la API
    final response = await http.get(listingsUrl, headers: headers);

    // Si la solicitud fue exitosa (código 200)
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta
      final listingsData = json.decode(response.body)['data'];
      final List<CryptoDetail> cryptoDetails = [];

      // Recorre cada criptomoneda recibida
      for (final coinData in listingsData) {
        final symbol = coinData['symbol'].toString().toUpperCase();
        final quote = coinData['quote']['USD'];
        final docRef = _firestore
            .collection('crypto_details')
            .doc(symbol); // Referencia al documento Firestore

        // Crea el objeto CryptoDetail con los datos obtenidos
        final cryptoDetail = CryptoDetail(
          id: coinData['id'].toString(),
          name: coinData['name'] ?? symbol,
          symbol: symbol,
          cmcRank: coinData['cmc_rank'] ?? 0,
          priceUsd: (quote['price'] as num?)?.toDouble() ?? 0,
          volumeUsd24Hr: (quote['volume_24h'] as num?)?.toDouble() ?? 0,
          percentChange24h:
              (quote['percent_change_24h'] as num?)?.toDouble() ?? 0,
          percentChange7d:
              (quote['percent_change_7d'] as num?)?.toDouble() ?? 0,
          marketCapUsd: (quote['market_cap'] as num?)?.toDouble() ?? 0,
          circulatingSupply:
              (coinData['circulating_supply'] as num?)?.toDouble() ?? 0,
          totalSupply: (coinData['total_supply'] as num?)?.toDouble(),
          maxSupply: (coinData['max_supply'] as num?)?.toDouble(),
          logoUrl:
              'https://s2.coinmarketcap.com/static/img/coins/64x64/${coinData["id"]}.png',
        );

        // Guarda o actualiza la info en Firestore con timestamp
        await docRef.set({
          'id': cryptoDetail.id,
          'name': cryptoDetail.name,
          'symbol': cryptoDetail.symbol,
          'cmcRank': cryptoDetail.cmcRank,
          'priceUsd': cryptoDetail.priceUsd,
          'volumeUsd24Hr': cryptoDetail.volumeUsd24Hr,
          'percentChange24h': cryptoDetail.percentChange24h,
          'percentChange7d': cryptoDetail.percentChange7d,
          'marketCapUsd': cryptoDetail.marketCapUsd,
          'circulatingSupply': cryptoDetail.circulatingSupply,
          'totalSupply': cryptoDetail.totalSupply,
          'maxSupply': cryptoDetail.maxSupply,
          'logoUrl': cryptoDetail.logoUrl,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Añade a la lista de resultados
        cryptoDetails.add(cryptoDetail);
      }
      // Devuelve la lista de objetos CryptoDetail
      return cryptoDetails;
    } else {
      // Si hubo error en la solicitud, lanza una excepción con el código de estado
      throw Exception(
        'Error al obtener datos de CoinMarketCap: ${response.statusCode}',
      );
    }
  }

  /// Método para obtener criptomonedas almacenadas en caché (Firestore)
  Future<List<CryptoDetail>> getCachedCryptoDetails() async {
    // Obtiene todos los documentos de la colección `crypto_details`
    final snapshot = await _firestore.collection('crypto_details').get();
    final List<CryptoDetail> cachedDetails = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;

      // Verifica si el timestamp es menor a 720 minutos (12 horas)
      if (timestamp != null &&
          DateTime.now().difference(timestamp.toDate()).inMinutes < 720) {
        cachedDetails.add(CryptoDetail.fromFirestore(data));
      }
    }
    // Retorna máximo 100 criptomonedas válidas en caché
    return cachedDetails.take(100).toList();
  }
}
