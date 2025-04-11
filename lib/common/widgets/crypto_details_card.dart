// Importa el paquete de Flutter para construir interfaces gráficas.
import 'package:flutter/material.dart';
// Importa el modelo de criptomoneda para utilizar sus propiedades.
import '../../core/models/crypto.dart';

/// Widget que representa una tarjeta con los detalles básicos de una criptomoneda.
/// Permite manejar toques (tap) mediante una función de callback.
class CryptoDetailsCard extends StatelessWidget {
  // Objeto Crypto que contiene la información de la criptomoneda.
  final Crypto crypto;
  // Callback que se ejecuta cuando el usuario toca la tarjeta.
  final VoidCallback onTap;

  // Constructor de la tarjeta, requiere la criptomoneda y la función de callback.
  const CryptoDetailsCard({
    super.key,
    required this.crypto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Detecta cuando el usuario toca la tarjeta y ejecuta el callback.
      onTap: onTap,
      child: Card(
        // Color de fondo oscuro para la tarjeta.
        color: const Color(0xFF303030),
        // Borde redondeado para una apariencia moderna.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        // Sombra para dar efecto de elevación.
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Muestra el logotipo de la criptomoneda usando una URL.
            Image.network(
              crypto.logoUrl,
              height: 50,
              width: 50,
              // En caso de error al cargar la imagen, muestra un ícono de error.
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red);
              },
            ),
            const SizedBox(height: 8), // Espacio entre la imagen y el nombre.
            // Muestra el nombre de la criptomoneda en texto blanco.
            Text(crypto.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
