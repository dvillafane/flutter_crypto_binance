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

// Evento para marcar o desmarcar una crypto como favorita
class ToggleFavoriteSymbol extends CryptoEvent {
  final String symbol;
  const ToggleFavoriteSymbol(this.symbol);
  @override
  List<Object?> get props => [symbol];
}

// Evento para alternar entre vista de todas y vista de favoritas
class ToggleFavoritesView extends CryptoEvent {}

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
  /// Lista de objetos CryptoDetail con los datos de cada criptomoneda
  final List<CryptoDetail> cryptos;

  /// Mapa que asocia cada símbolo de crypto a un Color
  final Map<String, Color> priceColors;

  /// Indica si la conexión al WebSocket está activa
  final bool isWebSocketConnected;

  /// Conjunto de símbolos marcados como favoritos por el usuario
  final Set<String> favoriteSymbols;

  /// Si es true, la UI mostrará solo las criptos favoritas
  final bool showFavorites;

  /// Constructor que recibe todos los campos obligatorios.
  /// favoriteSymbols y showFavorites tienen valores por defecto.
  const CryptoLoaded({
    required this.cryptos,
    required this.priceColors,
    required this.isWebSocketConnected,
    this.favoriteSymbols = const {},
    this.showFavorites = false,
  });

  /// Método para crear una nueva instancia modificando solo los campos
  /// que se pasen como parámetro, manteniendo el resto igual.
  CryptoLoaded copyWith({
    List<CryptoDetail>? cryptos,
    Map<String, Color>? priceColors,
    bool? isWebSocketConnected,
    Set<String>? favoriteSymbols,
    bool? showFavorites,
  }) {
    return CryptoLoaded(
      cryptos: cryptos ?? this.cryptos,
      priceColors: priceColors ?? this.priceColors,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      favoriteSymbols: favoriteSymbols ?? this.favoriteSymbols,
      showFavorites: showFavorites ?? this.showFavorites,
    );
  }

  /// Equatable props: lista de propiedades que se usan para comparar
  /// dos instancias de CryptoLoaded y determinar si son iguales.
  @override
  List<Object?> get props => [
    cryptos,
    priceColors,
    isWebSocketConnected,
    favoriteSymbols,
    showFavorites,
  ];
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
    on<ToggleFavoriteSymbol>(_onToggleFavoriteSymbol);
    on<ToggleFavoritesView>(_onToggleFavoritesView);

    // Iniciamos cargando criptomonedas
    add(LoadCryptos());
  }

  // Manejo del evento LoadCryptos
  // Manejo del evento LoadCryptos: carga criptomonedas desde caché o API
  Future<void> _onLoadCryptos(
    LoadCryptos event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      debugPrint('Cargando criptomonedas desde caché...');
      // Intentamos cargar datos almacenados localmente
      List<CryptoDetail> cryptos =
          await _cryptoService.getCachedCryptoDetails();

      // Si no hay datos en caché, cargamos desde la API
      if (cryptos.isEmpty) {
        debugPrint('Caché vacío, cargando desde API...');
        cryptos = await _cryptoService.fetchTop100CryptoDetails();
      } else {
        debugPrint('Usando datos en caché');
      }

      // Ordenamos las criptomonedas por precio de forma descendente
      cryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));

      // Guardamos los precios iniciales para detectar cambios luego
      for (var crypto in cryptos) {
        _previousPrices[crypto.symbol] = crypto.priceUsd;
      }

      // Nos conectamos al WebSocket para recibir actualizaciones en tiempo real
      debugPrint('Conectando WebSocket...');
      _pricesService.connect();
      _pricesSubscription = _pricesService.pricesStream.listen(
        (prices) =>
            add(PricesUpdated(prices: prices)), // Evento que actualiza precios
        onError:
            (error) => add(DisconnectWebSocket()), // Desconectamos si hay error
      );

      // Emitimos el nuevo estado con los datos cargados
      emit(
        CryptoLoaded(
          cryptos: cryptos,
          priceColors: {
            for (var e in cryptos) e.symbol: Colors.white,
          }, // Inicialmente blanco
          isWebSocketConnected: true,
        ),
      );
    } catch (e) {
      // Si ocurre un error, emitimos estado de error
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  // Manejo del evento PricesUpdated: actualiza precios y colores
  void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final updatedColors = <String, Color>{};

      // Recorremos las criptos y actualizamos los precios y colores
      final updatedCryptos =
          currentState.cryptos.map((crypto) {
              final binanceSymbol = "${crypto.symbol}USDT".toLowerCase();

              final oldPrice =
                  _previousPrices[crypto.symbol] ?? crypto.priceUsd;
              final newPrice = event.prices[binanceSymbol] ?? crypto.priceUsd;

              // Determinamos el color en función del cambio de precio
              Color color = Colors.white;
              if (newPrice > oldPrice) {
                color = Colors.green; // Subió
              } else if (newPrice < oldPrice) {
                color = Colors.red; // Bajó
              }

              // Guardamos el color actualizado y el nuevo precio
              updatedColors[crypto.symbol] = color;
              _previousPrices[crypto.symbol] = newPrice;

              // Devolvemos una nueva instancia de la crypto con precio actualizado
              return CryptoDetail(
                symbol: crypto.symbol,
                name: crypto.name,
                priceUsd: newPrice,
                volumeUsd24Hr: crypto.volumeUsd24Hr,
                logoUrl: crypto.logoUrl,
              );
            }).toList()
            ..sort(
              (a, b) => b.priceUsd.compareTo(a.priceUsd),
            ); // Reordenamos por precio

      // Emitimos el nuevo estado con los cambios
      emit(
        currentState.copyWith(
          cryptos: updatedCryptos,
          priceColors: updatedColors,
        ),
      );
    }
  }

  // Evento ConnectWebSocket: se conecta al WebSocket si no está conectado
  void _onConnectWebSocket(ConnectWebSocket event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded && !currentState.isWebSocketConnected) {
      try {
        _pricesService.connect(); // Inicia conexión
        _pricesSubscription = _pricesService.pricesStream.listen(
          (prices) => add(PricesUpdated(prices: prices)),
          onError: (error) => add(DisconnectWebSocket()),
        );
        emit(currentState.copyWith(isWebSocketConnected: true));
      } catch (e) {
        emit(CryptoError(message: "Error al conectar WebSocket: $e"));
      }
    }
  }

  // Evento DisconnectWebSocket: se desconecta del WebSocket si está activo
  void _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded && currentState.isWebSocketConnected) {
      _pricesSubscription?.cancel(); // Cancelamos la suscripción
      _pricesService.disconnect(); // Desconectamos el servicio
      emit(currentState.copyWith(isWebSocketConnected: false));
    }
  }

  // Evento ToggleFavoriteSymbol: marca o desmarca una crypto como favorita
  void _onToggleFavoriteSymbol(
    ToggleFavoriteSymbol event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final favs = Set<String>.from(currentState.favoriteSymbols);
      if (!favs.add(event.symbol)) {
        favs.remove(event.symbol); // Si ya estaba, la quitamos
      }
      emit(currentState.copyWith(favoriteSymbols: favs));
    }
  }

  // Evento ToggleFavoritesView: alterna entre vista general y vista de favoritas
  void _onToggleFavoritesView(
    ToggleFavoritesView event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      emit(currentState.copyWith(showFavorites: !currentState.showFavorites));
    }
  }

  // Override del método close: se ejecuta cuando se destruye el BLoC
  // Aquí liberamos los recursos y cancelamos las suscripciones activas
  @override
  Future<void> close() {
    _pricesSubscription?.cancel(); // Cancelamos escucha de precios
    _pricesService.dispose(); // Cerramos el servicio de precios
    return super.close(); // Llamamos al cierre base del BLoC
  }
}
