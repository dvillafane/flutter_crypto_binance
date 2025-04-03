import 'package:equatable/equatable.dart';

class CryptoDetail extends Equatable {
  final String id;
  final int rank;
  final String symbol;
  final String name;
  final double supply;
  final double? maxSupply;
  final double marketCapUsd;
  final double volumeUsd24Hr;
  final double priceUsd;
  final String logoUrl;

  const CryptoDetail({
    required this.id,
    required this.rank,
    required this.symbol,
    required this.name,
    required this.supply,
    this.maxSupply,
    required this.marketCapUsd,
    required this.volumeUsd24Hr,
    required this.priceUsd,
    required this.logoUrl,
  });

  factory CryptoDetail.fromJson(Map<String, dynamic> json) {
    return CryptoDetail(
      id: json['id'],
      rank: int.tryParse(json['rank']) ?? 0,
      symbol: json['symbol'],
      name: json['name'],
      supply: double.tryParse(json['supply']) ?? 0,
      maxSupply: json['maxSupply'] != null ? double.tryParse(json['maxSupply']) : null,
      marketCapUsd: double.tryParse(json['marketCapUsd']) ?? 0,
      volumeUsd24Hr: double.tryParse(json['volumeUsd24Hr']) ?? 0,
      priceUsd: double.tryParse(json['priceUsd']) ?? 0,
      logoUrl: 'https://assets.coincap.io/assets/icons/${json['symbol'].toLowerCase()}@2x.png',
    );
  }

  @override
  List<Object?> get props => [
        id,
        rank,
        symbol,
        name,
        supply,
        maxSupply,
        marketCapUsd,
        volumeUsd24Hr,
        priceUsd,
        logoUrl,
      ];
}
