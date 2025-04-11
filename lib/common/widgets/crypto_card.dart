// Importa el paquete de Flutter para widgets y estilos
import 'package:flutter/material.dart';
// Importa el modelo que representa los detalles de una criptomoneda
import '../../core/models/crypto_detail.dart';

/// Widget sin estado (StatelessWidget) que muestra una tarjeta con la información de una criptomoneda
class CryptoCard extends StatelessWidget {
  // Instancia del modelo de datos que contiene los detalles de la criptomoneda
  final CryptoDetail crypto;

  // Color personalizado para mostrar el precio (puede cambiar según suba o baje)
  final Color priceColor;

  // Constructor de la clase que requiere los parámetros [crypto] y [priceColor]
  const CryptoCard({
    super.key, // Permite manejar claves únicas en Flutter para widgets
    required this.crypto, // Requiere el objeto de datos de la criptomoneda
    required this.priceColor, // Requiere el color para el precio
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Color de fondo de la tarjeta (gris oscuro)
      color: Colors.grey[900],
      child: ListTile(
        // Muestra el logo de la criptomoneda desde la URL
        leading: Image.network(
          crypto.logoUrl, // URL del logo de la criptomoneda
          width: 32, // Ancho del logo
          height: 32, // Alto del logo
          // Si hay un error al cargar la imagen, muestra un ícono de error
          errorBuilder:
              (_, __, ___) => const Icon(Icons.error, color: Colors.red),
        ),
        // Nombre de la criptomoneda como título
        title: Text(
          crypto.name,
          style: const TextStyle(color: Colors.white), // Texto blanco
        ),
        // Precio en USD como subtítulo, formateado a dos decimales
        subtitle: Text(
          '\$${crypto.priceUsd.toStringAsFixed(2)} USD',
          style: TextStyle(
            color: priceColor,
          ), // Color dinámico según suba o baje
        ),
      ),
    );
  }
}
