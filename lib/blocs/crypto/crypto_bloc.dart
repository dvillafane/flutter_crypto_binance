import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_crypto_binance/models/crypto_detail.dart';
import '/services/crypto_detail_service.dart';
import '/services/websocket_prices_service.dart';
import 'crypto_event.dart';
import 'crypto_state.dart';

/// ----------------------------
/// 3. DEFINICIÓN DEL BLoC
/// ----------------------------

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoDetailService _cryptoService;
  final WebSocketPricesService _pricesService;
  final String userId;

  // Para almacenar precios anteriores y comparar si subieron o bajaron
  final Map<String, double> _previousPrices = {};

  // Suscripción al stream del WebSocket
  StreamSubscription<Map<String, double>>? _pricesSubscription;

  CryptoBloc({
    required this.userId,
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
    on<ChangeSortCriteria>(_onChangeSortCriteria); // Nuevo handler

    // Iniciamos cargando criptomonedas
    add(LoadCryptos());
  }

  // Función para cargar las favoritas desde Firestore
  Future<Set<String>> _loadFavoriteSymbols(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['favorites'] is List) {
        return Set<String>.from(data['favorites']);
      }
    }
    return {};
  }

  // Función para guardar las favoritas en Firestore
  Future<void> _saveFavoriteSymbols(
    String userId,
    Set<String> favorites,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'favorites': favorites.toList(),
    }, SetOptions(merge: true));
  }

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

      // Ordenar criptomonedas por precio de mayor a menor
      cryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));

      // Guardamos los precios iniciales para detectar cambios luego
      for (var crypto in cryptos) {
        _previousPrices[crypto.symbol] = crypto.priceUsd;
      }

      // Nos conectamos al WebSocket para recibir actualizaciones en tiempo real
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
          favoriteSymbols: favoriteSymbols,
        ),
      );
    } catch (e) {
      // Si ocurre un error, emitimos estado de error
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  // Manejo del evento PricesUpdated
  /// Actualiza los precios de las criptomonedas y asigna colores según la variación
  void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final updatedColors = <String, Color>{};
      // Recorremos las criptos y actualizamos los precios y colores
      final updatedCryptos =
          currentState.cryptos.map((crypto) {
            final binanceSymbol = "${crypto.symbol}USDT".toLowerCase();
            final oldPrice = _previousPrices[crypto.symbol] ?? crypto.priceUsd;
            final newPrice = event.prices[binanceSymbol] ?? crypto.priceUsd;

            // Determinar color según cambio de precio
            Color color = Colors.white;
            if (newPrice > oldPrice) {
              color = Colors.green; // Subió
            } else if (newPrice < oldPrice) {
              color = Colors.red; // Bajó
            }

            updatedColors[crypto.symbol] = color;
            _previousPrices[crypto.symbol] = newPrice;

            // Devolver cripto actualizada
            return CryptoDetail(
              id: crypto.id,
              name: crypto.name,
              symbol: crypto.symbol,
              cmcRank: crypto.cmcRank,
              priceUsd: newPrice,
              volumeUsd24Hr: crypto.volumeUsd24Hr,
              percentChange24h: crypto.percentChange24h,
              percentChange7d: crypto.percentChange7d,
              marketCapUsd: crypto.marketCapUsd,
              circulatingSupply: crypto.circulatingSupply,
              totalSupply: crypto.totalSupply,
              maxSupply: crypto.maxSupply,
              logoUrl: crypto.logoUrl,
            );
          }).toList();

      // Ordenar según el criterio actual
      switch (currentState.sortCriteria) {
        case 'priceUsd':
          updatedCryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
          break;
        case 'cmcRank':
          updatedCryptos.sort((a, b) => a.cmcRank.compareTo(b.cmcRank));
          break;
      }

      // Emitir nuevo estado
      emit(
        currentState.copyWith(
          cryptos: updatedCryptos,
          priceColors: updatedColors,
        ),
      );
    }
  }

  void _onChangeSortCriteria(
    ChangeSortCriteria event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      List<CryptoDetail> sortedCryptos = List.from(currentState.cryptos);
      switch (event.criteria) {
        case 'priceUsd':
          sortedCryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
          break;
        case 'cmcRank':
          sortedCryptos.sort((a, b) => a.cmcRank.compareTo(b.cmcRank));
          break;
      }
      emit(
        currentState.copyWith(
          cryptos: sortedCryptos,
          sortCriteria: event.criteria,
        ),
      );
    }
  }

  // Manejo de la conexión y desconexión del WebSocket
  /// Conecta al WebSocket y escucha los precios en tiempo real
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

  /// Desconecta del WebSocket y cancela la suscripción
  /// Si el WebSocket ya está desconectado, no hace nada
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

  // Manejo del evento ToggleFavoriteSymbol
  /// Alterna el estado de favorito de una criptomoneda
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
      // Guardamos las favoritas actualizadas en Firestore
      _saveFavoriteSymbols(userId, favs);
    }
  }

  /// Cambia la vista entre todas las criptomonedas y solo las favoritas
  void _onToggleFavoritesView(
    ToggleFavoritesView event,
    Emitter<CryptoState> emit,
  ) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      emit(currentState.copyWith(showFavorites: !currentState.showFavorites));
    }
  }

  /// Cierra el BLoC y cancela la suscripción al WebSocket
  /// También se asegura de que el servicio de precios se cierre correctamente
  @override
  Future<void> close() {
    _pricesSubscription?.cancel(); // Cancelamos escucha de precios
    _pricesService.dispose(); // Cerramos el servicio de precios
    return super.close(); // Llamamos al cierre base del BLoC
  }
}
