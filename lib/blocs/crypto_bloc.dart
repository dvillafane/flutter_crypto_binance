import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../models/crypto_detail.dart'; // Cambiado a CryptoDetail
import '../services/crypto_detail_service.dart'; // Servicio ajustado
import '../services/websocket_prices_service.dart';

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

abstract class CryptoState extends Equatable {
  const CryptoState();
  @override
  List<Object?> get props => [];
}

class CryptoLoading extends CryptoState {}

class CryptoLoaded extends CryptoState {
  final List<CryptoDetail> cryptos; // Cambiado a CryptoDetail
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

class CryptoError extends CryptoState {
  final String message;
  const CryptoError({required this.message});
  @override
  List<Object?> get props => [message];
}

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoDetailService _cryptoService; // Servicio actualizado
  final WebSocketPricesService _pricesService;
  final Map<String, double> _previousPrices = {};
  StreamSubscription<Map<String, double>>? _pricesSubscription;

  CryptoBloc({
    required CryptoDetailService cryptoService,
    required WebSocketPricesService pricesService,
  })  : _cryptoService = cryptoService,
        _pricesService = pricesService,
        super(CryptoLoading()) {
    on<LoadCryptos>(_onLoadCryptos);
    on<PricesUpdated>(_onPricesUpdated);
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);

    add(LoadCryptos());
  }

  Future<void> _onLoadCryptos(
    LoadCryptos event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      debugPrint('Cargando criptomonedas...');
      final cryptos = await _cryptoService.fetchTop100CryptoDetails();
      cryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd)); // Orden descendente

      for (var crypto in cryptos) {
        _previousPrices[crypto.symbol] = crypto.priceUsd;
      }

      debugPrint('Conectando WebSocket al inicio...');
      _pricesService.connect();
      _pricesSubscription = _pricesService.pricesStream.listen(
        (prices) {
          debugPrint('Precios recibidos: $prices');
          add(PricesUpdated(prices: prices));
        },
        onError: (error) {
          debugPrint('Error en WebSocket: $error');
          add(DisconnectWebSocket());
        },
      );

      emit(
        CryptoLoaded(
          cryptos: cryptos,
          priceColors: {for (var e in cryptos) e.symbol: Colors.white},
          isWebSocketConnected: true,
        ),
      );
      debugPrint('Estado inicial emitido con ${cryptos.length} criptomonedas');
    } catch (e) {
      debugPrint('Error al cargar criptomonedas: $e');
      emit(CryptoError(message: e.toString()));
    }
  }

  void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
    final currentState = state;
    if (currentState is CryptoLoaded) {
      debugPrint('Actualizando precios con: ${event.prices}');
      final Map<String, Color> updatedColors = {};
      final List<CryptoDetail> updatedCryptos =
          currentState.cryptos.map((crypto) {
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
      }).toList();

      updatedCryptos.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
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
    _pricesSubscription?.cancel();
    _pricesService.dispose();
    debugPrint('BLoC cerrado y recursos liberados');
    return super.close();
  }
}