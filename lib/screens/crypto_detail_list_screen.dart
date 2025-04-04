import 'package:flutter/material.dart';
import '../services/crypto_detail_service.dart';
import '../models/crypto_detail.dart';

class CryptoDetailListScreen extends StatefulWidget {
  @override
  _CryptoDetailListScreenState createState() => _CryptoDetailListScreenState();
}

class _CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  late Future<List<CryptoDetail>> _initialCryptoDetailsFuture;
  late Stream<Map<String, double>> _priceStream;
  List<CryptoDetail> _cryptoDetails = [];

  @override
  void initState() {
    super.initState();
    final service = CryptoDetailService();
    _initialCryptoDetailsFuture = service.getCachedCryptoDetails().then((cached) async {
      if (cached.length >= 100) {
        return cached;
      }
      return service.fetchTop100CryptoDetails();
    });
    _priceStream = service.streamRealTimePrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Top 100 Criptomonedas')),
      body: FutureBuilder<List<CryptoDetail>>(
        future: _initialCryptoDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            if (_cryptoDetails.isEmpty) {
              _cryptoDetails = snapshot.data!;
            }
            return StreamBuilder<Map<String, double>>(
              stream: _priceStream,
              builder: (context, streamSnapshot) {
                if (streamSnapshot.hasData) {
                  final priceUpdates = streamSnapshot.data!;
                  for (var i = 0; i < _cryptoDetails.length; i++) {
                    final newPrice = priceUpdates[_cryptoDetails[i].symbol];
                    if (newPrice != null) {
                      _cryptoDetails[i] = CryptoDetail(
                        symbol: _cryptoDetails[i].symbol,
                        name: _cryptoDetails[i].name,
                        priceUsd: newPrice,
                        volumeUsd24Hr: _cryptoDetails[i].volumeUsd24Hr,
                        logoUrl: _cryptoDetails[i].logoUrl,
                      );
                    }
                  }
                }
                return ListView.builder(
                  itemCount: _cryptoDetails.length,
                  itemBuilder: (context, index) {
                    final detail = _cryptoDetails[index];
                    return Card(
                      child: ListTile(
                        leading: Image.network(
                          detail.logoUrl,
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => Icon(Icons.error),
                        ),
                        title: Text(detail.name),
                        subtitle: Text('\$${detail.priceUsd.toStringAsFixed(2)} USD'),
                        onTap: () => _showCryptoDetailDialog(context, detail),
                      ),
                    );
                  },
                );
              },
            );
          }
          return Container();
        },
      ),
    );
  }

  void _showCryptoDetailDialog(BuildContext context, CryptoDetail detail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.network(
                detail.logoUrl,
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) => Icon(Icons.error),
              ),
              SizedBox(width: 8),
              Text(detail.name),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Símbolo: ${detail.symbol}'),
              Text('Precio: \$${detail.priceUsd.toStringAsFixed(2)} USD'),
              Text('Volumen 24h: \$${detail.volumeUsd24Hr.toStringAsFixed(2)} USD'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}