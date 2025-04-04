// Importación de paquetes necesarios
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../models/crypto_detail.dart';
import '../services/crypto_detail_service.dart';
import '../services/websocket_prices_service.dart';

/// ----------------------------
/// DEFINICIÓN DE EVENTOS
/// ----------------------------

// Clase base para los eventos del BLoC
abstract class CryptoEvent extends Equatable {
  const CryptoEvent();
  @override
  List<Object?> get props => [];
}

// Evento para cargar criptomonedas (desde caché o API)
class LoadCryptos extends CryptoEvent {}

// Evento que se dispara cuando llegan nuevos precios del WebSocket
class PricesUpdated extends CryptoEvent {
  final Map<String, double> prices;
  const PricesUpdated({required this.prices});
  @override
  List<Object?> get props => [prices];
}

// Evento para iniciar la conexión al WebSocket
class ConnectWebSocket extends CryptoEvent {}

// Evento para desconectar el WebSocket
class DisconnectWebSocket extends CryptoEvent {}

/// ----------------------------
/// DEFINICIÓN DE ESTADOS
/// ----------------------------

// Clase base para los estados del BLoC
abstract class CryptoState extends Equatable {
  const CryptoState();
  @override
  List<Object?> get props => [];
}

// Estado mientras se cargan las criptomonedas
class CryptoLoading extends CryptoState {}

// Estado cuando las criptomonedas han sido cargadas correctamente
class CryptoLoaded extends CryptoState {
  final List<CryptoDetail> cryptos;
  final Map<String, Color> priceColors;
  final bool isWebSocketConnected;

  const CryptoLoaded({
    required this.cryptos,
    required this.priceColors,
    required this.isWebSocketConnected,
  });

  @override
  List<Object?> get props => [cryptos, priceColors, isWebSocketConnected];
}

// Estado de error
class CryptoError extends CryptoState {
  final String message;
  const CryptoError({required this.message});
  @override
  List<Object?> get props => [message];
}

/// ----------------------------
/// DEFINICIÓN DEL BLoC
/// ----------------------------

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoDetailService _cryptoService;
  final WebSocketPricesService _pricesService;

  // Para almacenar precios anteriores y comparar si subieron o bajaron
  final Map<String, double> _previousPrices = {};

  // Suscripción al stream del WebSocket
  StreamSubscription<Map<String, double>>? _pricesSubscription;

  CryptoBloc({
    required CryptoDetailService cryptoService,
    required WebSocketPricesService pricesService,
  }) : _cryptoService = cryptoService,
       _pricesService = pricesService,
       super(CryptoLoading()) {
    // Registramos los handlers de eventos
    on<LoadCryptos>(_onLoadCryptos);
    on<PricesUpdated>(_onPricesUpdated);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);

    // Iniciamos cargando criptomonedas
    add(LoadCryptos());
  }

  // Manejo del evento LoadCryptos
  Future<void> _onLoadCryptos(
    LoadCryptos event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      debugPrint('Cargando criptomonedas desde caché...');
      List<CryptoDetail> cryptos =
          await _cryptoService.getCachedCryptoDetails();

      // Si el caché está vacío, se hace la petición a la API
      if (cryptos.isEmpty) {
        debugPrint('Caché vacío, cargando desde API...');
        cryptos = await _cryptoService.fetchTop100CryptoDetails();
      } else {
        debugPrint('Usando datos en caché');
      }

      // Ordenamos las criptos por precio (descendente)
      cryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));

      // Guardamos los precios iniciales
      for (var crypto in cryptos) {
        _previousPrices[crypto.symbol] = crypto.priceUsd;
      }

      // Conectamos al WebSocket para recibir precios en tiempo real
      debugPrint('Conectando WebSocket...');
      _pricesService.connect();
      _pricesSubscription = _pricesService.pricesStream.listen(
        (prices) =>
            add(PricesUpdated(prices: prices)), // Se dispara PricesUpdated
        onError: (error) => add(DisconnectWebSocket()), // Manejo de errores
      );

      emit(
        CryptoLoaded(
          cryptos: cryptos,
          priceColors: {for (var e in cryptos) e.symbol: Colors.white},
          isWebSocketConnected: true,
        ),
      );
    } catch (e) {
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  // Manejo del evento PricesUpdated (cambios en precios)
  void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final Map<String, Color> updatedColors = {};
      final List<CryptoDetail> updatedCryptos =
          currentState.cryptos.map((crypto) {
            final binanceSymbol = "${crypto.symbol}USDT".toLowerCase();
            final oldPrice = _previousPrices[crypto.symbol] ?? crypto.priceUsd;
            final newPrice = event.prices[binanceSymbol] ?? crypto.priceUsd;

            // Determinamos el color según si el precio subió o bajó
            Color color = Colors.white;
            if (newPrice > oldPrice) {
              color = Colors.green;
            } else if (newPrice < oldPrice) {
              color = Colors.red;
            }

            // Actualizamos color y precio previo
            updatedColors[crypto.symbol] = color;
            _previousPrices[crypto.symbol] = newPrice;

            // Creamos una nueva instancia actualizada
            return CryptoDetail(
              symbol: crypto.symbol,
              name: crypto.name,
              priceUsd: newPrice,
              volumeUsd24Hr: crypto.volumeUsd24Hr,
              logoUrl: crypto.logoUrl,
            );
          }).toList();

      // Reordenamos después de la actualización
      updatedCryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));

      // Emitimos nuevo estado
      emit(
        CryptoLoaded(
          cryptos: updatedCryptos,
          priceColors: updatedColors,
          isWebSocketConnected: currentState.isWebSocketConnected,
        ),
      );
    }
  }

  // Conectar WebSocket si no está conectado
  void _onConnectWebSocket(ConnectWebSocket event, Emitter<CryptoState> emit) {
    if (state is CryptoLoaded) {
      final currentState = state as CryptoLoaded;
      if (!currentState.isWebSocketConnected) {
        try {
          _pricesService.connect();
          _pricesSubscription = _pricesService.pricesStream.listen(
            (prices) => add(PricesUpdated(prices: prices)),
            onError: (error) => add(DisconnectWebSocket()),
          );

          emit(
            CryptoLoaded(
              cryptos: currentState.cryptos,
              priceColors: currentState.priceColors,
              isWebSocketConnected: true,
            ),
          );
        } catch (e) {
          emit(CryptoError(message: "Error al conectar WebSocket: $e"));
        }
      }
    }
  }

  // Desconectar el WebSocket si está conectado
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
      }
    }
  }

  // Cancelamos suscripciones y limpiamos recursos al cerrar el BLoC
  @override
  Future<void> close() {
    _pricesSubscription?.cancel();
    _pricesService.dispose();
    return super.close();
  }
}
