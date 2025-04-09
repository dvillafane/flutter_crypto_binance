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

  // Temporizador para actualización automática
  Timer? _updateTimer;

  CryptoBloc({
    required this.userId,
    required CryptoDetailService cryptoService,
    required WebSocketPricesService pricesService,
  })  : _cryptoService = cryptoService,
        _pricesService = pricesService,
        super(CryptoLoading()) {
    // Registramos los handlers de eventos
    on<LoadCryptos>(_onLoadCryptos);
    on<PricesUpdated>(_onPricesUpdated);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<ToggleFavoriteSymbol>(_onToggleFavoriteSymbol);
    on<ToggleFavoritesView>(_onToggleFavoritesView);
    on<ChangeSortCriteria>(_onChangeSortCriteria);
    on<AutoUpdateCryptos>(_onAutoUpdateCryptos); // Nuevo handler para actualización automática

    // Iniciamos cargando criptomonedas
    add(LoadCryptos());

    // Configuramos el temporizador para actualizar automáticamente cada 5 minutos
    _updateTimer = Timer.periodic(const Duration(minutes: 60), (timer) {
      add(AutoUpdateCryptos()); // Disparamos el evento en lugar de llamar directamente al método
    });
  }

  // Función para cargar las favoritas desde Firestore
  Future<Set<String>> _loadFavoriteSymbols(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'favorites': favorites.toList(),
    }, SetOptions(merge: true));
  }

  // Manejo del evento LoadCryptos
  Future<void> _onLoadCryptos(LoadCryptos event, Emitter<CryptoState> emit) async {
    try {
      debugPrint('Cargando criptomonedas desde caché...');
      List<CryptoDetail> cryptos = await _cryptoService.getCachedCryptoDetails();

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
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  // Manejo del evento PricesUpdated
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

      switch (currentState.sortCriteria) {
        case 'priceUsd':
          updatedCryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
          break;
        case 'cmcRank':
          updatedCryptos.sort((a, b) => a.cmcRank.compareTo(b.cmcRank));
          break;
      }

      emit(
        currentState.copyWith(
          cryptos: updatedCryptos,
          priceColors: updatedColors,
        ),
      );
    }
  }

  void _onChangeSortCriteria(ChangeSortCriteria event, Emitter<CryptoState> emit) {
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

  void _onDisconnectWebSocket(DisconnectWebSocket event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded && currentState.isWebSocketConnected) {
      _pricesSubscription?.cancel();
      _pricesService.disconnect();
      emit(currentState.copyWith(isWebSocketConnected: false));
    }
  }

  void _onToggleFavoriteSymbol(ToggleFavoriteSymbol event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      final favs = Set<String>.from(currentState.favoriteSymbols);
      if (!favs.add(event.symbol)) {
        favs.remove(event.symbol);
      }
      emit(currentState.copyWith(favoriteSymbols: favs));
      _saveFavoriteSymbols(userId, favs);
    }
  }

  void _onToggleFavoritesView(ToggleFavoritesView event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      emit(currentState.copyWith(showFavorites: !currentState.showFavorites));
    }
  }

  // Manejo del evento AutoUpdateCryptos
  Future<void> _onAutoUpdateCryptos(AutoUpdateCryptos event, Emitter<CryptoState> emit) async {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      // Emitimos el estado CryptoUpdating con los datos actuales
      emit(CryptoUpdating(
        previousCryptos: currentState.cryptos,
        priceColors: currentState.priceColors,
        isWebSocketConnected: currentState.isWebSocketConnected,
        favoriteSymbols: currentState.favoriteSymbols,
        showFavorites: currentState.showFavorites,
        sortCriteria: currentState.sortCriteria,
      ));

      try {
        // Obtenemos los nuevos datos desde la API
        final newCryptos = await _cryptoService.fetchTop100CryptoDetails();
        // Ordenamos según el criterio actual
        switch (currentState.sortCriteria) {
          case 'priceUsd':
            newCryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
            break;
          case 'cmcRank':
            newCryptos.sort((a, b) => a.cmcRank.compareTo(b.cmcRank));
            break;
        }
        // Actualizamos los precios anteriores
        for (var crypto in newCryptos) {
          _previousPrices[crypto.symbol] = crypto.priceUsd;
        }
        // Emitimos el nuevo estado CryptoLoaded con los datos actualizados
        emit(CryptoLoaded(
          cryptos: newCryptos,
          priceColors: {for (var e in newCryptos) e.symbol: Colors.white},
          isWebSocketConnected: currentState.isWebSocketConnected,
          favoriteSymbols: currentState.favoriteSymbols,
          showFavorites: currentState.showFavorites,
          sortCriteria: currentState.sortCriteria,
        ));
      } catch (e) {
        // Si hay error, volvemos al estado anterior
        emit(currentState);
        debugPrint('Error al actualizar criptomonedas: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _pricesSubscription?.cancel();
    _pricesService.dispose();
    _updateTimer?.cancel();
    return super.close();
  }
}
