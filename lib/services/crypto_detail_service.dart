// services/crypto_detail_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_detail.dart';

class CryptoDetailService {
  final String baseUrl = 'https://api.coincap.io/v2/assets';

  Future<CryptoDetail> fetchCryptoDetail(String assetId) async {
    final url = Uri.parse('$baseUrl/$assetId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // La información se encuentra en data['data']
      return CryptoDetail.fromJson(data['data']);
    } else {
      throw Exception('Error al obtener detalles de la criptomoneda: ${response.statusCode}');
    }
  }
}
