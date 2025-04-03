import 'dart:async';
import 'dart:math'; // Se agrega para calcular el jitter
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../models/crypto.dart';
import '../services/crypto_service.dart';
import '../services/websocket_prices_service.dart';

/// Definición de eventos para el BLoC de criptomonedas, usando Equatable
abstract class CryptoEvent extends Equatable {
  const CryptoEvent();

  @override
  List<Object?> get props => [];
}

/// Evento que se dispara al cargar la lista inicial de criptomonedas
class LoadCryptos extends CryptoEvent {
  const LoadCryptos();

  @override
  List<Object?> get props => [];
}

/// Evento que se dispara al recibir nuevos precios vía WebSocket
class PricesUpdated extends CryptoEvent {
  final Map<String, double> prices;

  const PricesUpdated({required this.prices});

  @override
  List<Object?> get props => [prices];
}

/// Evento para reconectar el WebSocket
class ReconnectWebSocket extends CryptoEvent {
  const ReconnectWebSocket();

  @override
  List<Object?> get props => [];
}

/// Definición de estados que puede emitir el BLoC de criptomonedas, usando Equatable
abstract class CryptoState extends Equatable {
  const CryptoState();

  @override
  List<Object?> get props => [];
}

/// Estado que representa que las criptomonedas están en proceso de carga
class CryptoLoading extends CryptoState {
  const CryptoLoading();

  @override
  List<Object?> get props => [];
}

/// Estado que indica que la carga de criptomonedas se ha completado
class CryptoLoaded extends CryptoState {
  final List<Crypto> cryptos;
  final Map<String, Color> priceColors;

  const CryptoLoaded({required this.cryptos, required this.priceColors});

  @override
  List<Object?> get props => [cryptos, priceColors];
}

/// Estado que representa un error durante la carga o actualización de criptomonedas
class CryptoError extends CryptoState {
  final String message;

  const CryptoError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// BLoC que gestiona la carga y actualización de criptomonedas en tiempo real
class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final CryptoService _cryptoService; // Servicio para obtener datos de criptomonedas
  final WebSocketPricesService _pricesService; // Servicio para recibir precios en tiempo real

  /// Mapa que almacena los precios previos de cada criptomoneda para detectar cambios
  final Map<String, double> _previousPrices = {};

  /// Suscripción al stream de precios provenientes del WebSocket
  late StreamSubscription<Map<String, double>> _pricesSubscription;

  /// Constructor que inicializa los servicios y define los eventos manejados
  CryptoBloc({
    required CryptoService cryptoService,
    required WebSocketPricesService pricesService,
  })  : _cryptoService = cryptoService,
        _pricesService = pricesService,
        super(const CryptoLoading()) {
    // Registrar el evento para cargar las criptomonedas
    on<LoadCryptos>(_onLoadCryptos);

    // Registrar el evento para actualizar los precios
    on<PricesUpdated>(_onPricesUpdated);

    // Registrar el evento para reconexión
    on<ReconnectWebSocket>(_onReconnectWebSocket);

    // Disparar el evento inicial de carga de criptomonedas al crear el BLoC
    add(const LoadCryptos());
  }

  /// Método que maneja el evento de carga inicial de criptomonedas
  Future<void> _onLoadCryptos(
    LoadCryptos event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      // Obtener la lista de criptomonedas desde el servicio
      final cryptos = await _cryptoService.fetchCryptos();

      // Ordenar la lista en orden descendente según el precio
      cryptos.sort((a, b) => b.price.compareTo(a.price));

      // Inicializar el mapa de precios previos con los valores actuales
      for (var crypto in cryptos) {
        _previousPrices[crypto.id] = crypto.price;
      }

      // Suscribirse al stream de precios del WebSocket
      _pricesSubscription = _pricesService.pricesStream.listen((prices) {
        // Disparar un evento con los precios actualizados
        add(PricesUpdated(prices: prices));
      },
      onError: (error) {
        // Se dispara la reconexión automáticamente en caso de error
        add(const ReconnectWebSocket());
      },
      );
      // Emitir el estado cargado con la lista de criptomonedas y colores predeterminados
      emit(
        CryptoLoaded(
          cryptos: cryptos,
          priceColors: {for (var e in cryptos) e.id: Colors.black},
        ),
      );
    } catch (e) {
      // Emitir un estado de error si la carga falla
      emit(CryptoError(message: e.toString()));
    }
  }

  /// Método que maneja el evento de actualización de precios en tiempo real
void _onPricesUpdated(PricesUpdated event, Emitter<CryptoState> emit) {
  // Se obtiene el estado actual del bloc
  final currentState = state;

  // Se verifica que el estado actual sea del tipo CryptoLoaded
  if (currentState is CryptoLoaded) {
    // Mapa que almacenará el color actualizado para cada criptomoneda basado en el cambio de precio
    final Map<String, Color> updatedColors = {};

    // Se crea una lista de criptomonedas actualizadas mapeando cada una del estado actual
    final List<Crypto> updatedCryptos = currentState.cryptos.map((crypto) {
      // Se construye el símbolo usado en Binance, concatenando el símbolo en mayúsculas con "USDT"
      // Ejemplo: para crypto.symbol "btc" se obtiene "BTCUSDT"
      String binanceSymbol = "${crypto.symbol.toUpperCase()}USDT";

      // Se obtiene el precio anterior de la criptomoneda, si no existe se toma el precio actual
      final double oldPrice = _previousPrices[crypto.id] ?? crypto.price;

      // Se obtiene el nuevo precio desde el evento, usando el símbolo en minúsculas, si no existe se usa el precio actual
      final double newPrice = event.prices[binanceSymbol.toLowerCase()] ?? crypto.price;

      // Se define un color inicial (blanco) para la representación del precio
      Color color = const Color(0xFFFFFFFF);

      // Se asigna el color verde si el nuevo precio es mayor que el precio anterior
      if (newPrice > oldPrice) {
        color = Colors.green;
      // Se asigna el color rojo si el nuevo precio es menor que el precio anterior
      } else if (newPrice < oldPrice) {
        color = Colors.red;
      }

      // Se actualiza el mapa de colores con el color determinado para esta criptomoneda
      updatedColors[crypto.id] = color;

      // Se actualiza el precio anterior con el nuevo precio para futuras comparaciones
      _previousPrices[crypto.id] = newPrice;

      // Se retorna una nueva instancia de Crypto con el precio actualizado
      return Crypto(
        id: crypto.id,
        name: crypto.name,
        symbol: crypto.symbol,
        price: newPrice,
        logoUrl: crypto.logoUrl,
      );
    }).toList();

    // Se ordena la lista de criptomonedas en forma descendente según su precio
    updatedCryptos.sort((a, b) => b.price.compareTo(a.price));

    // Se emite el nuevo estado CryptoLoaded con la lista de criptomonedas actualizadas y el mapa de colores de precios
    emit(CryptoLoaded(cryptos: updatedCryptos, priceColors: updatedColors));
  }
}


  /// Handler para reconectar el WebSocket con optimización de retroceso exponencial y jitter
  Future<void> _onReconnectWebSocket(
    ReconnectWebSocket event,
    Emitter<CryptoState> emit,
  ) async {
    await _pricesSubscription.cancel();

    int retryCount = 0;
    const int maxRetries = 5; // Número máximo de intentos de reconexión
    const int baseDelay = 1; // Tiempo base en segundos
    final random = Random();
    bool reconnected = false;

    while (retryCount < maxRetries && !reconnected) {
      try {
        // Calcular el tiempo de espera usando retroceso exponencial con jitter
        final double delaySeconds = baseDelay * pow(2, retryCount) + random.nextDouble();
        await Future.delayed(Duration(milliseconds: (delaySeconds * 1000).round()));

        // Intentar reconectar el WebSocket
        _pricesService.reconnect();

        // Reactivar la suscripción al stream de precios, con reconexión automática en caso de error
        _pricesSubscription = _pricesService.pricesStream.listen((prices) {
          add(PricesUpdated(prices: prices));
        }, onError: (error) {
          // Disparar nuevamente el evento de reconexión si ocurre otro error
          add(const ReconnectWebSocket());
        });

        reconnected = true;
      } catch (e) {
        retryCount++;
      }
    }

    // Notificar al usuario si se alcanzó el máximo número de intentos sin éxito
    if (!reconnected) {
      emit(
        CryptoError(message: "No se pudo reconectar después de $maxRetries intentos."),
      );
    }
  }

  /// Método que se llama al cerrar el BLoC para liberar recursos
  @override
  Future<void> close() {
    _pricesSubscription.cancel(); // Cancelar la suscripción al WebSocket
    _pricesService.dispose(); // Liberar recursos del servicio
    return super.close();
  }
}
