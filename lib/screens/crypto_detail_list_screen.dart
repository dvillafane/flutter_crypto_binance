// Importa los paquetes necesarios para la interfaz y el manejo de estados.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/crypto_bloc.dart';
import '../widgets/crypto_details_card.dart';
import 'crypto_detail_screen.dart';

/// Pantalla que muestra una lista de criptomonedas en forma de cuadrícula.
class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  @override
  State<CryptoDetailListScreen> createState() => _CryptoDetailListScreenState();
}

class _CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  // Variable que almacena la consulta de búsqueda ingresada por el usuario.
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Configura el color de fondo de la pantalla en negro.
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Espaciado alrededor del contenido.
        child: Column(
          children: [
            // Campo de texto para buscar criptomonedas.
            TextField(
              style: const TextStyle(color: Colors.white), // Texto en color blanco.
              decoration: InputDecoration(
                hintText: 'Buscar criptomoneda...', // Texto de sugerencia.
                hintStyle: const TextStyle(color: Colors.white70), // Color del texto de sugerencia.
                prefixIcon: const Icon(Icons.search, color: Colors.white70), // Icono de búsqueda.
                filled: true, // Campo de texto con fondo lleno.
                fillColor: Colors.grey[800], // Color de fondo del campo.
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Bordes redondeados.
                  borderSide: BorderSide.none, // Sin borde visible.
                ),
              ),
              // Actualiza la consulta de búsqueda cada vez que el usuario escribe.
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase(); // Convierte el texto a minúsculas.
                });
              },
            ),
            const SizedBox(height: 8), // Espaciado entre el campo de búsqueda y la lista.

            // Se utiliza un BlocBuilder para escuchar los cambios de estado del BLoC.
            Expanded(
              child: BlocBuilder<CryptoBloc, CryptoState>(
                builder: (context, state) {
                  // Muestra un indicador de carga mientras se obtienen los datos.
                  if (state is CryptoLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } 
                  // Muestra la lista de criptomonedas cargadas.
                  else if (state is CryptoLoaded) {
                    // Filtra las criptomonedas según la consulta de búsqueda.
                    final filteredCryptos = state.cryptos.where((crypto) =>
                        crypto.name.toLowerCase().contains(_searchQuery) || // Filtra por nombre.
                        crypto.symbol.toLowerCase().contains(_searchQuery)   // Filtra por símbolo.
                    ).toList();

                    // Muestra las criptomonedas en una cuadrícula.
                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0), // Espaciado interno.
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Número de columnas en la cuadrícula.
                        childAspectRatio: 1, // Relación de aspecto de los elementos.
                        crossAxisSpacing: 8, // Espaciado horizontal entre elementos.
                        mainAxisSpacing: 8, // Espaciado vertical entre elementos.
                      ),
                      itemCount: filteredCryptos.length, // Número de elementos a mostrar.
                      itemBuilder: (context, index) {
                        final crypto = filteredCryptos[index];
                        return CryptoDetailsCard(
                          crypto: crypto,
                          onTap: () {
                            // Navega a la pantalla de detalles de la criptomoneda seleccionada.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CryptoDetailScreen(assetId: crypto.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } 
                  // Muestra un mensaje de error si ocurre un problema al cargar los datos.
                  else if (state is CryptoError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}', // Muestra el mensaje de error.
                        style: const TextStyle(color: Colors.red), // Texto en color rojo.
                      ),
                    );
                  }
                  // Devuelve un contenedor vacío si no se cumple ninguna condición.
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
