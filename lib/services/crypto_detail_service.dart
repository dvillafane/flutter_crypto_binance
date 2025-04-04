import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crypto_detail.dart';

class CryptoDetailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String coinMarketCapBaseUrl = 'https://pro-api.coinmarketcap.com';
  final String binanceWsUrl = 'wss://stream.binance.com:9443/ws/!ticker@arr';
  final String apiKey = '78e4fb3b-8828-4d00-8210-501ea8951fe3'; // Reemplaza con tu clave API de CoinMarketCap

  // Cargar las 100 primeras criptomonedas desde CoinMarketCap
  Future<List<CryptoDetail>> fetchTop100CryptoDetails() async {
    final headers = {'X-CMC_PRO_API_KEY': apiKey};
    final listingsUrl = Uri.parse(
      '$coinMarketCapBaseUrl/v1/cryptocurrency/listings/latest?start=1&limit=100&convert=USD',
    );

    final response = await http.get(listingsUrl, headers: headers);

    if (response.statusCode == 200) {
      final listingsData = json.decode(response.body)['data'];
      final List<CryptoDetail> cryptoDetails = [];

      for (final coinData in listingsData) {
        final symbol = coinData['symbol'].toString().toUpperCase();
        final docRef = _firestore.collection('crypto_details').doc(symbol);
        final cryptoDetail = CryptoDetail(
          symbol: symbol,
          name: coinData['name'] ?? symbol,
          priceUsd: (coinData['quote']['USD']['price'] as num?)?.toDouble() ?? 0,
          volumeUsd24Hr: (coinData['quote']['USD']['volume_24h'] as num?)?.toDouble() ?? 0,
          logoUrl: 'https://s2.coinmarketcap.com/static/img/coins/64x64/${coinData["id"]}.png',
        );

        await docRef.set({
          'symbol': cryptoDetail.symbol,
          'name': cryptoDetail.name,
          'priceUsd': cryptoDetail.priceUsd,
          'volumeUsd24Hr': cryptoDetail.volumeUsd24Hr,
          'logoUrl': cryptoDetail.logoUrl,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        cryptoDetails.add(cryptoDetail);
      }

      return cryptoDetails;
    } else {
      throw Exception('Error al obtener datos de CoinMarketCap: ${response.statusCode}');
    }
  }

  // Obtener datos desde Firestore como caché inicial
  Future<List<CryptoDetail>> getCachedCryptoDetails() async {
    final snapshot = await _firestore.collection('crypto_details').get();
    final List<CryptoDetail> cachedDetails = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null &&
          DateTime.now().difference(timestamp.toDate()).inMinutes < 1440) {
        cachedDetails.add(CryptoDetail.fromFirestore(data));
      }
    }

    return cachedDetails.take(100).toList(); // Limitar a 100
  }

  // Stream de precios en tiempo real desde Binance WebSocket
  Stream<Map<String, double>> streamRealTimePrices() {
    final channel = IOWebSocketChannel.connect(binanceWsUrl);
    return channel.stream.map((data) {
      final List<dynamic> tickers = json.decode(data);
      final Map<String, double> priceUpdates = {};
      for (final ticker in tickers) {
        final symbol = ticker['s'].replaceAll('USDT', '').toUpperCase();
        final price = double.tryParse(ticker['c']) ?? 0;
        priceUpdates[symbol] = price;
      }
      return priceUpdates;
    });
  }
}