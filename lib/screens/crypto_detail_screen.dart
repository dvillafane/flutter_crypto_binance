// Importa los paquetes necesarios para la interfaz de usuario y el manejo de estados.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../blocs/crypto_detail_bloc.dart';
import '../services/crypto_detail_service.dart';

/// Pantalla que muestra los detalles de una criptomoneda específica.
class CryptoDetailScreen extends StatelessWidget {
  // Identificador único del activo (criptomoneda) cuyos detalles se mostrarán.
  final String assetId;

  const CryptoDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Crea una instancia del BLoC y carga los detalles de la criptomoneda al iniciarse.
      create:
          (context) =>
              CryptoDetailBloc(detailService: CryptoDetailService())
                ..add(LoadCryptoDetail(assetId: assetId)),
      child: Scaffold(
        // Fondo de la pantalla en color negro.
        backgroundColor: Colors.black,
        body: BlocBuilder<CryptoDetailBloc, CryptoDetailState>(
          builder: (context, state) {
            // Muestra un indicador de carga mientras se obtienen los datos.
            if (state is CryptoDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Muestra los detalles de la criptomoneda cuando los datos se han cargado correctamente.
            else if (state is CryptoDetailLoaded) {
              final detail = state.detail;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0), // Espaciado interno.
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Ocupa solo el espacio necesario.
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Centra los elementos.
                    children: [
                      // Muestra el nombre de la criptomoneda con un estilo destacado.
                      Text(
                        detail.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16), // Espaciado entre elementos.
                      // Muestra el logo de la criptomoneda usando una URL.
                      Image.network(detail.logoUrl, width: 100, height: 100),
                      const SizedBox(height: 16), // Espaciado adicional.
                      // Tarjeta que contiene los detalles de la criptomoneda.
                      Card(
                        color:
                            Colors.grey[900], // Color de fondo de la tarjeta.
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordes redondeados.
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            16.0,
                          ), // Margen interno de la tarjeta.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fila que muestra el símbolo de la criptomoneda.
                              _buildInfoRow(
                                'Símbolo',
                                detail.symbol,
                                LucideIcons.hash,
                              ), // Muestra "BTC" en lugar de "BTCUSDT"
                              _buildInfoRow(
                                'Volumen 24h',
                                '\$${detail.volumeUsd24Hr.toStringAsFixed(2)}',
                                LucideIcons.pieChart,
                              ),
                              // Fila que muestra el precio actual de la criptomoneda.
                              _buildInfoRow(
                                'Precio',
                                '\$${detail.priceUsd.toStringAsFixed(2)}',
                                LucideIcons.trendingUp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Muestra un mensaje de error si hay algún problema al cargar los detalles.
            else if (state is CryptoDetailError) {
              return Center(
                child: Text(
                  'Error: ${state.message}', // Mensaje de error detallado.
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            // Devuelve un contenedor vacío si no se cumple ninguna de las condiciones anteriores.
            return Container();
          },
        ),
      ),
    );
  }

  /// Método que construye una fila de información con un ícono, una etiqueta y un valor.
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Espaciado vertical entre filas.
      child: Row(
        children: [
          // Ícono representativo del dato mostrado.
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 8), // Espacio entre el ícono y el texto.
          // Texto que muestra el nombre del dato (por ejemplo, "Símbolo").
          Expanded(
            child: Text(
              "$label: ",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          // Texto que muestra el valor asociado al dato.
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
