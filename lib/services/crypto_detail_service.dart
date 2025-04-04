// Importa el paquete 'dart:convert' para manejar la codificación y decodificación de JSON.
import 'dart:convert';
// Importa el paquete 'http' para realizar solicitudes HTTP.
import 'package:http/http.dart' as http;
// Importa el paquete de Firestore para interactuar con la base de datos.
import 'package:cloud_firestore/cloud_firestore.dart';
// Importa el modelo que representa los detalles de la criptomoneda.
import '../models/crypto_detail.dart';

/// Servicio encargado de obtener detalles específicos de una criptomoneda desde la API o Firestore.
class CryptoDetailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String baseUrl = 'https://api.binance.com';

  /// Método asíncrono que obtiene los detalles de una criptomoneda específica
  /// mediante su identificador (assetId).
  Future<CryptoDetail> fetchCryptoDetail(String assetId) async {
    final String upperAssetId = assetId.toUpperCase();
    final String tradingPair = '${upperAssetId}USDT'; // Par completo: "BTCUSDT"
    final docRef = _firestore.collection('crypto_details').doc(upperAssetId);

    // Paso 1: Consultar Firestore primero
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      final timestamp = data['timestamp'] as Timestamp?;
      // Verifica si los datos están actualizados (menos de 5 minutos)
      if (timestamp != null &&
          DateTime.now().difference(timestamp.toDate()).inMinutes < 60) {
        return CryptoDetail.fromFirestore(data);
      }
    }

    // Paso 2: Si no hay datos o están desactualizados, consultar Binance
    final url = Uri.parse('$baseUrl/api/v3/ticker/24hr?symbol=$tradingPair');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final cryptoDetail = CryptoDetail.fromJson(data, tradingPair);

      // Paso 3: Guardar los datos en Firestore
      await docRef.set({
        'symbol': cryptoDetail.symbol,
        'tradingPair': cryptoDetail.tradingPair,
        'name': cryptoDetail.name,
        'priceUsd': cryptoDetail.priceUsd,
        'volumeUsd24Hr': cryptoDetail.volumeUsd24Hr,
        'logoUrl': cryptoDetail.logoUrl,
        'timestamp': FieldValue.serverTimestamp(), // Marca de tiempo del servidor
      }, SetOptions(merge: true)); // Usa merge para no sobrescribir innecesariamente

      return cryptoDetail;
    } else {
      throw Exception(
        'Error al obtener detalles de la criptomoneda: ${response.statusCode}',
      );
    }
  }
}