import 'package:flutter/material.dart';
import '../models/crypto_detail.dart'; // Importamos CryptoDetail

class CryptoCard extends StatelessWidget {
  final CryptoDetail crypto; // Cambiamos a CryptoDetail
  final Color priceColor;
  final Color cardColor;

  const CryptoCard({
    super.key,
    required this.crypto,
    required this.priceColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 6.0,
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cardColor,
          child: crypto.logoUrl.isNotEmpty
              ? Image.network(crypto.logoUrl)
              : const Icon(Icons.monetization_on, color: Colors.white),
        ),
        title: Text(
          '${crypto.name} (${crypto.symbol})',
          style: const TextStyle(
            fontSize: 19.0,
            fontWeight: FontWeight.w600,
            color: Color(0xDDFFFFFF),
          ),
        ),
        subtitle: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: priceColor,
          ),
          child: Text('\$${crypto.priceUsd.toStringAsFixed(2)}'), // Usamos priceUsd
        ),
      ),
    );
  }
}