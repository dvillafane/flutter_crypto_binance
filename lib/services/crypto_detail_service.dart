// Importaciones necesarias
import 'dart:convert'; // Para decodificar la respuesta JSON
import 'package:http/http.dart'
    as http; // Cliente HTTP para hacer solicitudes a la API
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore para almacenamiento en la nube
import '../models/crypto_detail.dart'; // Modelo de datos

// Servicio para obtener detalles de criptomonedas
class CryptoDetailService {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // URL base de la API de CoinMarketCap
  final String coinMarketCapBaseUrl = 'https://pro-api.coinmarketcap.com';

  // Clave API personal de CoinMarketCap (⚠️ Deberías ocultarla en producción)
  final String apiKey = '78e4fb3b-8828-4d00-8210-501ea8951fe3';

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
        final symbol = coinData['symbol'].toString().toUpperCase(); // Ej. BTC
        final docRef = _firestore
            .collection('crypto_details')
            .doc(symbol); // Referencia al documento Firestore

        // Crea el objeto CryptoDetail con los datos obtenidos
        final cryptoDetail = CryptoDetail(
          symbol: symbol,
          name: coinData['name'] ?? symbol,
          priceUsd:
              (coinData['quote']['USD']['price'] as num?)?.toDouble() ?? 0,
          volumeUsd24Hr:
              (coinData['quote']['USD']['volume_24h'] as num?)?.toDouble() ?? 0,
          logoUrl:
              'https://s2.coinmarketcap.com/static/img/coins/64x64/${coinData["id"]}.png',
        );

        // Guarda o actualiza la info en Firestore con timestamp
        await docRef.set({
          'symbol': cryptoDetail.symbol,
          'name': cryptoDetail.name,
          'priceUsd': cryptoDetail.priceUsd,
          'volumeUsd24Hr': cryptoDetail.volumeUsd24Hr,
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

      // Filtra solo los datos con menos de 12 horas de antigüedad (720 minutos)
      if (timestamp != null &&
          DateTime.now().difference(timestamp.toDate()).inMinutes < 720) {
        cachedDetails.add(CryptoDetail.fromFirestore(data));
      }
    }

    // Retorna máximo 100 criptomonedas válidas en caché
    return cachedDetails.take(100).toList();
  }
}
