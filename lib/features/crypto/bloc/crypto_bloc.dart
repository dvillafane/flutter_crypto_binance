import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/crypto_detail.dart';
import '../../../core/services/crypto_detail_service.dart';
import '../../../core/services/websocket_prices_service.dart';
import 'crypto_event.dart';
import 'crypto_state.dart';

/// ----------------------------
/// 3. DEFINICIÓN DEL BLoC
/// ----------------------------

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoDetailService _cryptoService;
  final WebSocketPricesService _pricesService;
  final String userId;
  final bool isGuest;

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
        isGuest = userId == 'guest',
        super(CryptoLoading()) {
    // Registramos los handlers de eventos
    on<LoadCryptos>(_onLoadCryptos);
    on<PricesUpdated>(_onPricesUpdated);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
    on<ToggleFavoriteSymbol>(_onToggleFavoriteSymbol);
    on<ToggleFavoritesView>(_onToggleFavoritesView);
    on<ChangeSortCriteria>(_onChangeSortCriteria);
    on<AutoUpdateCryptos>(_onAutoUpdateCryptos);

    add(LoadCryptos());
    _setupAutoUpdateTimer(); // Configuramos el temporizador basado en Firestore
  }

  // Nueva función para configurar el temporizador basado en el timestamp de Firestore
  Future<void> _setupAutoUpdateTimer() async {
    const updateInterval = Duration(minutes: 360); // Intervalo de actualización

    // Obtener el timestamp de la última actualización desde Firestore
    final docRef = FirebaseFirestore.instance.collection('crypto_updates').doc('last_update');
    final doc = await docRef.get();
    Timestamp? lastUpdateTimestamp;

    if (doc.exists) {
      lastUpdateTimestamp = doc.data()?['timestamp'] as Timestamp?;
    }

    Duration timeToNextUpdate;
    if (lastUpdateTimestamp != null) {
      final lastUpdate = lastUpdateTimestamp.toDate();
      final timeSinceLastUpdate = DateTime.now().difference(lastUpdate);
      timeToNextUpdate = updateInterval - timeSinceLastUpdate;

      // Si ya pasó el intervalo, actualizamos inmediatamente y reiniciamos
      if (timeToNextUpdate.isNegative) {
        add(AutoUpdateCryptos());
        timeToNextUpdate = updateInterval;
      }
    } else {
      // Si no hay registro previo, actualizamos ahora y usamos el intervalo completo
      add(AutoUpdateCryptos());
      timeToNextUpdate = updateInterval;
    }

    // Configuramos el temporizador con el tiempo calculado
    _updateTimer = Timer.periodic(updateInterval, (timer) {
      add(AutoUpdateCryptos());
    });

    // Ejecutamos la primera actualización con el tiempo restante
    Timer(timeToNextUpdate, () {
      add(AutoUpdateCryptos());
    });
  }

  Future<Set<String>> _loadFavoriteSymbols(String userId) async {
    if (isGuest) return {};
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
    if (isGuest) return;
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
        onError: (error) {
          debugPrint('Error en la suscripción al WebSocket: $error');
          add(DisconnectWebSocket());
        },
        onDone: () {
          debugPrint('Suscripción al WebSocket finalizada');
        },
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
          onError: (error) {
            debugPrint('Error en la suscripción al WebSocket: $error');
            add(DisconnectWebSocket());
          },
          onDone: () {
            debugPrint('Suscripción al WebSocket finalizada');
          },
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
      _pricesSubscription = null; // Limpia la referencia
      _pricesService.disconnect();
      debugPrint('Desconectando WebSocket desde el BLoC');
      emit(currentState.copyWith(isWebSocketConnected: false));
    }
  }

  void _onToggleFavoriteSymbol(ToggleFavoriteSymbol event, Emitter<CryptoState> emit) {
    if (isGuest) return;
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
      // Indicamos que la actualización está en curso
      emit(currentState.copyWith(isUpdating: true));

      try {
        debugPrint('Llamando a la API para nuevos datos...');
        final newCryptos = await _cryptoService.fetchTop100CryptoDetails();
        debugPrint('Datos recibidos, ordenando...');
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
        debugPrint('Emitting nuevos datos actualizados');
        
        // Actualizamos el timestamp en Firestore
        await FirebaseFirestore.instance.collection('crypto_updates').doc('last_update').set({
          'timestamp': FieldValue.serverTimestamp(),
        });

        emit(currentState.copyWith(
          cryptos: newCryptos,
          priceColors: {for (var e in newCryptos) e.symbol: Colors.white},
          isUpdating: false, // La actualización ha terminado
        ));
      } catch (e) {
        debugPrint('Error al actualizar criptomonedas: $e');
        emit(currentState.copyWith(isUpdating: false)); // Volvemos al estado normal en caso de error
      }
    }
  }

  @override
  Future<void> close() {
    _pricesSubscription?.cancel();
    _pricesSubscription = null;
    _pricesService.dispose();
    _updateTimer?.cancel();
    debugPrint('CryptoBloc cerrado');
    return super.close();
  }
}