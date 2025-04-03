// widgets/crypto_details_card.dart
import 'package:flutter/material.dart';
import '../models/crypto.dart';

class CryptoDetailsCard extends StatelessWidget {
  final Crypto crypto;
  final VoidCallback onTap;

  const CryptoDetailsCard({
    super.key,
    required this.crypto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF303030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              crypto.logoUrl,
              height: 50,
              width: 50,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red);
              },
            ),
            const SizedBox(height: 8),
            Text(
              crypto.name,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
