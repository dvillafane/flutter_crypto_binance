// Importación de paquetes necesarios
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Nueva importación para Firestore
import '../models/crypto_detail.dart';
import '../services/crypto_detail_service.dart';
import '../services/websocket_prices_service.dart';

/// ----------------------------
/// DEFINICIÓN DEL BLoC
/// ----------------------------

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoDetailService _cryptoService;
  final WebSocketPricesService _pricesService;
  final String userId; // Nueva propiedad para almacenar el ID del usuario

  // Para almacenar precios anteriores y comparar si subieron o bajaron
  final Map<String, double> _previousPrices = {};

  // Suscripción al stream del WebSocket
  StreamSubscription<Map<String, double>>? _pricesSubscription;

  CryptoBloc({
    required this.userId, // Requerimos el userId en el constructor
    required CryptoDetailService cryptoService,
    required WebSocketPricesService pricesService,
  })  : _cryptoService = cryptoService,
        _pricesService = pricesService,
        super(CryptoLoading()) {
    on<LoadCryptos>(_onLoadCryptos);
    on<PricesUpdated>(_onPricesUpdated);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<ToggleFavoriteSymbol>(_onToggleFavoriteSymbol);
    on<ToggleFavoritesView>(_onToggleFavoritesView);

    // Iniciamos cargando criptomonedas
    add(LoadCryptos());
  }

  // Función para cargar las favoritas desde Firestore
  Future<Set<String>> _loadFavoriteSymbols(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['favorites'] is List) {
        return Set<String>.from(data['favorites']);
      }
    }
    return {};
  }

  // Función para guardar las favoritas en Firestore
  Future<void> _saveFavoriteSymbols(String userId, Set<String> favorites) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'favorites': favorites.toList()}, SetOptions(merge: true));
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

      if (cryptos.isEmpty) {
        debugPrint('Caché vacío, cargando desde API...');
        cryptos = await _cryptoService.fetchTop100CryptoDetails();
      } else {
        debugPrint('Usando datos en caché');
      }

      cryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));

      for (var crypto in cryptos) {
        _previousPrices[crypto.symbol] = crypto.priceUsd;
      }

      debugPrint('Conectando WebSocket...');
      _pricesService.connect();
      _pricesSubscription = _pricesService.pricesStream.listen(
        (prices) => add(PricesUpdated(prices: prices)),
        onError: (error) => add(DisconnectWebSocket()),
      );

      // Cargar las favoritas del usuario desde Firestore
      final favoriteSymbols = await _loadFavoriteSymbols(userId);

      emit(
        CryptoLoaded(
          cryptos: cryptos,
          priceColors: {for (var e in cryptos) e.symbol: Colors.white},
          isWebSocketConnected: true,
          favoriteSymbols: favoriteSymbols, // Pasamos las favoritas cargadas
        ),
      );
    } catch (e) {
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  // Manejo del evento ToggleFavoriteSymbol
  void _onToggleFavoriteSymbol(
    ToggleFavoriteSymbol event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final favs = Set<String>.from(currentState.favoriteSymbols);
      if (!favs.add(event.symbol)) {
        favs.remove(event.symbol); // Si ya estaba, lo quitamos
      }
      emit(currentState.copyWith(favoriteSymbols: favs));
      // Guardamos las favoritas actualizadas en Firestore
      _saveFavoriteSymbols(userId, favs);
    }
  }

  // Resto de los métodos permanecen igual
  void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final updatedColors = <String, Color>{};
      final updatedCryptos = currentState.cryptos.map((crypto) {
        final binanceSymbol = "${crypto.symbol}USDT".toLowerCase();
        final oldPrice = _previousPrices[crypto.symbol] ?? crypto.priceUsd;
        final newPrice = event.prices[binanceSymbol] ?? crypto.priceUsd;

        Color color = Colors.white;
        if (newPrice > oldPrice) {
          color = Colors.green;
        } else if (newPrice < oldPrice) {
          color = Colors.red;
        }

        updatedColors[crypto.symbol] = color;
        _previousPrices[crypto.symbol] = newPrice;

        return CryptoDetail(
          symbol: crypto.symbol,
          name: crypto.name,
          priceUsd: newPrice,
          volumeUsd24Hr: crypto.volumeUsd24Hr,
          logoUrl: crypto.logoUrl,
        );
      }).toList()
        ..sort((a, b) => b.priceUsd.compareTo(a.priceUsd));

      emit(
        currentState.copyWith(
          cryptos: updatedCryptos,
          priceColors: updatedColors,
        ),
      );
    }
  }

  void _onConnectWebSocket(ConnectWebSocket event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded && !currentState.isWebSocketConnected) {
      try {
        _pricesService.connect();
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

  void _onDisconnectWebSocket(
    DisconnectWebSocket event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded && currentState.isWebSocketConnected) {
      _pricesSubscription?.cancel();
      _pricesService.disconnect();
      emit(currentState.copyWith(isWebSocketConnected: false));
    }
  }

  void _onToggleFavoritesView(
    ToggleFavoritesView event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      emit(currentState.copyWith(showFavorites: !currentState.showFavorites));
    }
  }

  @override
  Future<void> close() {
    _pricesSubscription?.cancel();
    _pricesService.dispose();
    return super.close();
  }
}

// Eventos y estados permanecen igual, no se modifican
abstract class CryptoEvent extends Equatable {
  const CryptoEvent();
  @override
  List<Object?> get props => [];
}

class LoadCryptos extends CryptoEvent {}
class PricesUpdated extends CryptoEvent {
  final Map<String, double> prices;
  const PricesUpdated({required this.prices});
  @override
  List<Object?> get props => [prices];
}
class ConnectWebSocket extends CryptoEvent {}
class DisconnectWebSocket extends CryptoEvent {}
class ToggleFavoriteSymbol extends CryptoEvent {
  final String symbol;
  const ToggleFavoriteSymbol(this.symbol);
  @override
  List<Object?> get props => [symbol];
}
class ToggleFavoritesView extends CryptoEvent {}

abstract class CryptoState extends Equatable {
  const CryptoState();
  @override
  List<Object?> get props => [];
}

class CryptoLoading extends CryptoState {}

class CryptoLoaded extends CryptoState {
  final List<CryptoDetail> cryptos;
  final Map<String, Color> priceColors;
  final bool isWebSocketConnected;
  final Set<String> favoriteSymbols;
  final bool showFavorites;

  const CryptoLoaded({
    required this.cryptos,
    required this.priceColors,
    required this.isWebSocketConnected,
    this.favoriteSymbols = const {},
    this.showFavorites = false,
  });

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

  @override
  List<Object?> get props => [
        cryptos,
        priceColors,
        isWebSocketConnected,
        favoriteSymbols,
        showFavorites,
      ];
}

class CryptoError extends CryptoState {
  final String message;
  const CryptoError({required this.message});
  @override
  List<Object?> get props => [message];
}