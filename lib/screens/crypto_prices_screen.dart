// Importa el paquete material de Flutter, que provee componentes de interfaz gráfica.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto_bloc.dart';
import '../models/crypto.dart';
import '../widgets/crypto_card.dart';

/// Pantalla principal para mostrar los precios de las criptomonedas con buscador.
class CryptoPricesScreen extends StatefulWidget {
  const CryptoPricesScreen({super.key});

  @override
  State<CryptoPricesScreen> createState() => _CryptoPricesScreenState();
}

class _CryptoPricesScreenState extends State<CryptoPricesScreen> {
  // Variable para almacenar el texto ingresado en el campo de búsqueda.
  String searchQuery = "";

  // Controlador para el campo de búsqueda.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // Libera recursos asociados al controlador cuando el widget se elimina.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Establece el fondo de la pantalla en color negro.
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0, // Sin sombra en la barra superior.
        // Utiliza un Row en el título para colocar el buscador y el botón en la misma línea.
        title: Row(
          children: [
            // Campo de búsqueda expandido para ocupar la mayor parte del espacio.
            Expanded(
              child: TextField(
                controller: _searchController, // Controlador del texto ingresado.
                style: const TextStyle(color: Colors.white), // Estilo de texto en color blanco.
                decoration: InputDecoration(
                  hintText: "Buscar criptomoneda...", // Texto de sugerencia.
                  hintStyle: const TextStyle(color: Colors.grey), // Color del texto de sugerencia.
                  prefixIcon: const Icon(Icons.search, color: Colors.white), // Ícono de búsqueda.
                  filled: true, // Fondo relleno en el campo.
                  fillColor: Colors.grey[900], // Color de fondo del campo de búsqueda.
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20), // Bordes redondeados.
                    borderSide: BorderSide.none, // Sin borde visible.
                  ),
                ),
                // Actualiza el estado cuando cambia el texto en el buscador.
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8), // Espacio entre el campo y el botón.
            // Botón de recarga que reconecta el WebSocket para obtener precios actualizados.
            IconButton(
              icon: const Icon(Icons.refresh), // Ícono de recarga.
              color: const Color(0xFFD2E4FF), // Color del ícono.
              onPressed: () {
                // Dispara el evento para reconectar el WebSocket.
                context.read<CryptoBloc>().add(ReconnectWebSocket());
              },
            ),
          ],
        ),
      ),
      // Cuerpo de la pantalla que contiene la lista de criptomonedas.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea a la izquierda.
        children: [
          // Expande el bloque de contenido para ocupar todo el espacio disponible.
          Expanded(
            child: BlocBuilder<CryptoBloc, CryptoState>(
              builder: (context, state) {
                // Muestra un indicador de carga mientras se obtienen los datos.
                if (state is CryptoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } 
                // Muestra la lista de criptomonedas cuando los datos están cargados.
                else if (state is CryptoLoaded) {
                  // Filtro de criptomonedas basado en la búsqueda ingresada.
                  List<Crypto> filteredCryptos = state.cryptos;
                  if (searchQuery.isNotEmpty) {
                    filteredCryptos = filteredCryptos.where((crypto) {
                      // Filtra ignorando mayúsculas y minúsculas.
                      return crypto.name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          );
                    }).toList();
                  }

                  // Genera la lista de criptomonedas filtradas.
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0), // Espaciado alrededor de la lista.
                    itemCount: filteredCryptos.length, // Número de elementos en la lista.
                    itemBuilder: (context, index) {
                      final crypto = filteredCryptos[index];
                      return CryptoCard(
                        crypto: crypto, // Objeto de criptomoneda.
                        priceColor: state.priceColors[crypto.id] ?? Colors.white, // Color del precio.
                        cardColor: const Color(0xFF303030), // Color de fondo de la tarjeta.
                      );
                    },
                  );
                } 
                // Muestra un mensaje de error si ocurre un problema al cargar los datos.
                else if (state is CryptoError) {
                  return Center(
                    child: Text(
                      state.message, // Mensaje de error proveniente del estado.
                      style: const TextStyle(color: Colors.red), // Texto en color rojo.
                    ),
                  );
                }
                // Devuelve un contenedor vacío si no hay resultados ni errores.
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
