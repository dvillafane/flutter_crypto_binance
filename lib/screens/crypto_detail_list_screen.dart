// Importamos los paquetes necesarios
import 'package:flutter/material.dart'; // Paquete básico de widgets de Flutter
import 'package:flutter_bloc/flutter_bloc.dart'; // Para utilizar el patrón BLoC en Flutter
import 'package:flutter_crypto_binance/blocs/crypto/crypto_event.dart'; // Eventos del BLoC de criptomonedas
import 'package:flutter_crypto_binance/blocs/crypto/crypto_state.dart'; // Estados del BLoC de criptomonedas
import 'package:intl/intl.dart'; // Para formatear números de manera adecuada
import '../blocs/crypto/crypto_bloc.dart'; // Definición del BLoC que maneja la lógica de las criptomonedas
import '../models/crypto_detail.dart'; // Modelo de datos con los detalles de una criptomoneda

// Pantalla que muestra la lista de criptomonedas con sus detalles
class CryptoDetailListScreen extends StatefulWidget {
  const CryptoDetailListScreen({super.key});

  // Crea el estado asociado a esta pantalla
  @override
  CryptoDetailListScreenState createState() => CryptoDetailListScreenState();
}

// Estado de la pantalla anterior, permite gestionar cambios en la interfaz
class CryptoDetailListScreenState extends State<CryptoDetailListScreen> {
  String searchQuery = ""; // Almacena el texto del campo de búsqueda
  final TextEditingController _searchController =
      TextEditingController(); // Controlador para el campo de búsqueda
  final numberFormat = NumberFormat(
    '#,##0.00',
    'en_US',
  ); // Formateador de números, para mostrar cifras con separadores y decimales según el formato en_US

  // Método que se ejecuta cuando la pantalla se elimina de la jerarquía de widgets
  @override
  void dispose() {
    _searchController.dispose(); // Liberamos recursos del controlador
    super.dispose();
  }

  // Método que construye la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Definición de la barra superior de la aplicación
      appBar: AppBar(
        backgroundColor: Colors.black, // Color de fondo de la barra
        // Título "CRYPTOS" alineado a la izquierda
        title: const Text(
          'CRYPTOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // Título no centrado (alinea a la izquierda)
        titleSpacing: 16, // Espaciado a la izquierda del título
        // Campo de búsqueda integrado en la parte inferior de la AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            56,
          ), // Altura del área de búsqueda
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller:
                  _searchController, // Conecta el TextField al controlador
              style: const TextStyle(
                color: Colors.white,
              ), // Estilo del texto en el campo de búsqueda
              decoration: InputDecoration(
                hintText: "Buscar criptomoneda...", // Texto de sugerencia
                hintStyle: const TextStyle(
                  color: Colors.white70,
                ), // Estilo del texto de sugerencia
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                ), // Icono al inicio del campo
                filled: true,
                fillColor:
                    Colors.grey[800], // Color de fondo del campo de búsqueda
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Bordes redondeados
                  borderSide: BorderSide.none, // Sin borde definido
                ),
              ),
              // Actualiza el estado cada vez que cambia el texto del campo
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
        // Definición de los iconos de acción en el AppBar: ordenamiento, vista de favoritas y conexión WebSocket
        actions: [
          // Dropdown para seleccionar el criterio de ordenamiento
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              // Verificamos que los datos se hayan cargado correctamente
              if (state is CryptoLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DropdownButton<String>(
                    value:
                        state.sortCriteria, // Criterio de ordenamiento actual
                    // Configuración visual del dropdown
                    dropdownColor: Colors.grey[900],
                    underline: const SizedBox(), // Sin subrayado
                    items: const [
                      DropdownMenuItem(
                        value: 'priceUsd',
                        child: Text(
                          'Precio',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'cmcRank',
                        child: Text(
                          'Ranking',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    // Acción al seleccionar un nuevo criterio de ordenamiento
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CryptoBloc>().add(
                          ChangeSortCriteria(value),
                        );
                      }
                    },
                  ),
                );
              }
              // Si el estado no es CryptoLoaded, no mostramos nada
              return const SizedBox.shrink();
            },
          ),
          // Botón para alternar entre ver todas o solo las criptomonedas marcadas como favoritas
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              bool showFavorites = false;
              bool isEnabled = false;
              if (state is CryptoLoaded) {
                showFavorites =
                    state.showFavorites; // Si está activado el modo favoritos
                isEnabled = true; // Habilita el botón
              }
              return IconButton(
                icon: Icon(
                  // Muestra un ícono de corazón si las favoritas están activadas, o una lista en caso contrario
                  showFavorites ? Icons.favorite : Icons.format_list_bulleted,
                  color: Colors.white,
                ),
                tooltip:
                    showFavorites
                        ? 'Ver todas'
                        : 'Ver favoritas', // Texto de ayuda según el estado
                onPressed:
                    isEnabled
                        ? () => context.read<CryptoBloc>().add(
                          ToggleFavoritesView(), // Cambia el estado de vista entre todas y favoritas
                        )
                        : null,
              );
            },
          ),
          // Botón para activar o desactivar actualizaciones en tiempo real vía WebSocket
          BlocBuilder<CryptoBloc, CryptoState>(
            builder: (context, state) {
              if (state is CryptoLoaded) {
                return IconButton(
                  icon: Icon(
                    // Muestra un ícono de pausa si está conectado el WebSocket, o play si no lo está
                    state.isWebSocketConnected ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  tooltip:
                      state.isWebSocketConnected
                          ? 'Detener actualizaciones'
                          : 'Reanudar actualizaciones', // Texto de ayuda según el estado de la conexión
                  // Acción para conectar o desconectar el WebSocket
                  onPressed: () {
                    if (state.isWebSocketConnected) {
                      // Desconecta el WebSocket
                      context.read<CryptoBloc>().add(DisconnectWebSocket());
                    } else {
                      // Conecta el WebSocket
                      context.read<CryptoBloc>().add(ConnectWebSocket());
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      // Cuerpo principal de la pantalla que muestra la lista de criptomonedas
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (context, state) {
          if (state is CryptoLoading) {
            // Muestra un indicador de carga mientras se obtienen los datos
            return const Center(child: CircularProgressIndicator());
          } else if (state is CryptoLoaded) {
            // Filtra las criptomonedas según el texto ingresado en el campo de búsqueda (comparación en minúsculas)
            var iterable = state.cryptos.where(
              (c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()),
            );

            // Si está activado el modo "favoritas", se filtran también por aquellas marcadas como favoritas
            if (state.showFavorites) {
              iterable = iterable.where(
                (c) => state.favoriteSymbols.contains(c.symbol),
              );
            }
            final filtered =
                iterable.toList(); // Convierte el iterable a una lista

            // Si la lista filtrada está vacía, se muestra un mensaje informativo
            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  state.showFavorites
                      ? 'No tienes favoritas aún'
                      : 'No se encontró ninguna',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }

            // Construye una lista de elementos a partir de las criptomonedas filtradas
            return ListView.builder(
              itemCount: filtered.length, // Número de elementos en la lista
              itemBuilder: (context, i) {
                final detail = filtered[i]; // Detalle de la criptomoneda
                final isFav = state.favoriteSymbols.contains(
                  detail.symbol,
                ); // Verifica si la criptomoneda está marcada como favorita
                return Card(
                  color: Colors.grey[900], // Color de fondo de la tarjeta
                  child: ListTile(
                    // Muestra el ícono o logo de la criptomoneda usando una imagen de red
                    leading: Image.network(
                      detail.logoUrl,
                      width: 32,
                      height: 32,
                      // Muestra un ícono de error en caso de que falle la carga de la imagen
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(Icons.error, color: Colors.red),
                    ),
                    // Muestra el nombre de la criptomoneda
                    title: Text(
                      detail.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    // Muestra el precio con animación para reflejar cambios en el color según la variación de precio
                    subtitle: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 350),
                      style: TextStyle(
                        // Color del precio basado en el estado (puede cambiar según la variación)
                        color:
                            state.priceColors[detail.symbol] ?? Colors.white70,
                      ),
                      child: Text(
                        '\$${numberFormat.format(detail.priceUsd)} USD',
                      ),
                    ),
                    // Botón para marcar o desmarcar la criptomoneda como favorita
                    trailing: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white70,
                      ),
                      // Al presionar, se dispara un evento para alternar el estado de favorito
                      onPressed:
                          () => context.read<CryptoBloc>().add(
                            ToggleFavoriteSymbol(detail.symbol),
                          ),
                    ),
                    // Al tocar el elemento de la lista, se muestra un diálogo con más detalles de la criptomoneda
                    onTap: () => _showCryptoDetailDialog(context, detail),
                  ),
                );
              },
            );
          } else if (state is CryptoError) {
            // Si hubo un error al cargar los datos, se muestra un mensaje de error
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          // Por defecto, si no se cumple ninguna condición, no muestra nada
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Función que muestra un AlertDialog con la información detallada de la criptomoneda
  void _showCryptoDetailDialog(BuildContext context, CryptoDetail detail) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900], // Color de fondo del diálogo
            title: Row(
              children: [
                // Muestra el logo de la criptomoneda en el título
                Image.network(
                  detail.logoUrl,
                  width: 32,
                  height: 32,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.error, color: Colors.red),
                ),
                const SizedBox(width: 8), // Espacio entre el logo y el nombre
                // Muestra el nombre de la criptomoneda
                Text(detail.name, style: const TextStyle(color: Colors.white)),
              ],
            ),
            // Contenido del diálogo en un contenedor que permite desplazamiento
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muestra diversos detalles de la criptomoneda
                  Text(
                    'Símbolo: ${detail.symbol}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Ranking: #${detail.cmcRank}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Precio: \$${numberFormat.format(detail.priceUsd)} USD',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Volumen 24h: \$${numberFormat.format(detail.volumeUsd24Hr)} USD',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Cambio 24h: ${detail.percentChange24h.toStringAsFixed(2)}%',
                    style: TextStyle(
                      // Color verde si el cambio es positivo, rojo si es negativo
                      color:
                          detail.percentChange24h >= 0
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  Text(
                    'Cambio 7d: ${detail.percentChange7d.toStringAsFixed(2)}%',
                    style: TextStyle(
                      // Color verde si el cambio es positivo, rojo si es negativo
                      color:
                          detail.percentChange7d >= 0
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  Text(
                    'Capitalización de mercado: \$${numberFormat.format(detail.marketCapUsd)} USD',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Suministro circulante: ${numberFormat.format(detail.circulatingSupply)} ${detail.symbol}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  // Verifica y muestra el suministro total si existe
                  if (detail.totalSupply != null)
                    Text(
                      'Suministro total: ${numberFormat.format(detail.totalSupply!)} ${detail.symbol}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  // Verifica y muestra el suministro máximo si existe
                  if (detail.maxSupply != null)
                    Text(
                      'Suministro máximo: ${numberFormat.format(detail.maxSupply!)} ${detail.symbol}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            // Botón para cerrar el diálogo
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
