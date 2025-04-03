// Importaciones necesarias para el funcionamiento del BLoC y la gestión de eventos.
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../models/crypto.dart';
import '../services/crypto_service.dart';
import '../services/websocket_prices_service.dart';

// Definición de eventos para el BLoC.
abstract class CryptoEvent extends Equatable {
  const CryptoEvent();
  @override
  List<Object?> get props => [];
}

// Evento para cargar las criptomonedas al iniciar la aplicación.
class LoadCryptos extends CryptoEvent {}

// Evento que se dispara cuando se actualizan los precios desde el WebSocket.
class PricesUpdated extends CryptoEvent {
  final Map<String, double>
  prices; // Diccionario con el precio actualizado de cada criptomoneda.
  const PricesUpdated({required this.prices});
  @override
  List<Object?> get props => [prices];
}

// Eventos para conectar y desconectar el WebSocket.
class ConnectWebSocket extends CryptoEvent {}

class DisconnectWebSocket extends CryptoEvent {}

// Definición de los diferentes estados que puede tener el BLoC.
abstract class CryptoState extends Equatable {
  const CryptoState();
  @override
  List<Object?> get props => [];
}

// Estado mientras se están cargando las criptomonedas.
class CryptoLoading extends CryptoState {}

class CryptoLoaded extends CryptoState {
  final List<Crypto> cryptos; // Lista de criptomonedas cargadas.
  final Map<String, Color>
  priceColors; // Mapa que relaciona el ID con el color según la variación de precio.
  final bool isWebSocketConnected; // Estado de la conexión WebSocket.

  const CryptoLoaded({
    required this.cryptos,
    required this.priceColors,
    required this.isWebSocketConnected,
  });

  @override
  List<Object?> get props => [cryptos, priceColors, isWebSocketConnected];
}

// Estado de error si ocurre algún problema al cargar los datos.
class CryptoError extends CryptoState {
  final String message;
  const CryptoError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Implementación del BLoC para manejar los eventos y estados relacionados con criptomonedas.
class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoService _cryptoService; // Servicio para obtener criptomonedas.
  final WebSocketPricesService
  _pricesService; // Servicio para obtener precios en tiempo real.
  final Map<String, double> _previousPrices =
      {}; // Precios anteriores para comparar.
  StreamSubscription<Map<String, double>>?
  _pricesSubscription; // Suscripción al flujo de precios.

  // Constructor del BLoC, inicializa servicios y el estado inicial (cargando).
  CryptoBloc({
    required CryptoService cryptoService,
    required WebSocketPricesService pricesService,
  }) : _cryptoService = cryptoService,
       _pricesService = pricesService,
       super(CryptoLoading()) {
    // Manejadores de eventos registrados.
    on<LoadCryptos>(_onLoadCryptos);
    on<PricesUpdated>(_onPricesUpdated);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);

    // Inicia el proceso de carga al crear el BLoC.
    add(LoadCryptos());
  }
  // Método para cargar las criptomonedas desde el servicio.
  Future<void> _onLoadCryptos(
    LoadCryptos event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      debugPrint('Cargando criptomonedas...');
      final cryptos = await _cryptoService.fetchCryptos();
      cryptos.sort(
        (a, b) => b.price.compareTo(a.price),
      ); // Ordena de mayor a menor precio.

      // Guarda los precios iniciales.
      for (var crypto in cryptos) {
        _previousPrices[crypto.id] = crypto.price;
      }

      // Conexión inicial al WebSocket para recibir precios en tiempo real.
      debugPrint('Conectando WebSocket al inicio...');
      _pricesService.connect();
      _pricesSubscription = _pricesService.pricesStream.listen(
        (prices) {
          debugPrint('Precios recibidos en suscripción: $prices');
          add(PricesUpdated(prices: prices));
        },
        onError: (error) {
          debugPrint('Error en WebSocket: $error');
          add(DisconnectWebSocket());
        },
      );

      // Emite el estado con las criptomonedas cargadas.
      emit(
        CryptoLoaded(
          cryptos: cryptos,
          priceColors: {for (var e in cryptos) e.id: Colors.black},
          isWebSocketConnected: true,
        ),
      );
      debugPrint('Estado inicial emitido con ${cryptos.length} criptomonedas');
    } catch (e) {
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  // Método para actualizar los precios en tiempo real.
  void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      debugPrint('Actualizando precios con: ${event.prices}');
      final Map<String, Color> updatedColors = {};
      // Actualiza el precio y el color según la variación (subida/bajada).
      final List<Crypto> updatedCryptos =
          currentState.cryptos.map((crypto) {
            String binanceSymbol = "${crypto.symbol.toUpperCase()}USDT";
            final double oldPrice = _previousPrices[crypto.id] ?? crypto.price;
            final double newPrice =
                event.prices[binanceSymbol.toLowerCase()] ?? crypto.price;
            Color color = const Color(0xFFFFFFFF);
            if (newPrice > oldPrice) {
              color = Colors.green;
            } else if (newPrice < oldPrice) {
              color = Colors.red;
            }
            updatedColors[crypto.id] = color;
            _previousPrices[crypto.id] = newPrice;
            // Retorna el objeto actualizado.
            return Crypto(
              id: crypto.id,
              name: crypto.name,
              symbol: crypto.symbol,
              price: newPrice,
              logoUrl: crypto.logoUrl,
            );
          }).toList();
      // Actualiza el estado con los nuevos precios y colores.
      updatedCryptos.sort((a, b) => b.price.compareTo(a.price));
      emit(
        CryptoLoaded(
          cryptos: updatedCryptos,
          priceColors: updatedColors,
          isWebSocketConnected: currentState.isWebSocketConnected,
        ),
      );
      debugPrint('Estado actualizado con nuevos precios');
    }
  }

  // Método para conectar manualmente el WebSocket.
  void _onConnectWebSocket(ConnectWebSocket event, Emitter<CryptoState> emit) {
    if (state is CryptoLoaded) {
      final currentState = state as CryptoLoaded;
      if (!currentState.isWebSocketConnected) {
        try {
          _pricesService.connect();
          _pricesSubscription = _pricesService.pricesStream.listen(
            (prices) {
              add(PricesUpdated(prices: prices));
            },
            onError: (error) {
              add(DisconnectWebSocket());
            },
          );
          emit(
            CryptoLoaded(
              cryptos: currentState.cryptos,
              priceColors: currentState.priceColors,
              isWebSocketConnected: true,
            ),
          );
          debugPrint('WebSocket conectado manualmente');
        } catch (e) {
          emit(CryptoError(message: "Error al conectar WebSocket: $e"));
        }
      }
    }
  }

  // Método para desconectar el WebSocket.
  void _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<CryptoState> emit,
  ) {
    if (state is CryptoLoaded) {
      final currentState = state as CryptoLoaded;
      if (currentState.isWebSocketConnected) {
        _pricesSubscription?.cancel();
        _pricesService.disconnect();
        emit(
          CryptoLoaded(
            cryptos: currentState.cryptos,
            priceColors: currentState.priceColors,
            isWebSocketConnected: false,
          ),
        );
        debugPrint('WebSocket desconectado manualmente');
      }
    }
  }

  @override
  Future<void> close() {
    // Cancela la suscripción y libera recursos al cerrar el BLoC.
    _pricesSubscription?.cancel();
    _pricesService.dispose();
    debugPrint('BLoC cerrado y recursos liberados');
    return super.close();
  }
}
