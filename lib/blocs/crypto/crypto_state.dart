import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '/models/crypto_detail.dart';

/// ----------------------------
/// 2. DEFINICIÓN DE ESTADOS
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

  /// Lista de objetos CryptoDetail con los datos de cada criptomoneda
  final Map<String, Color> priceColors;

  /// Mapa que asocia cada símbolo de crypto a un Color
  final bool isWebSocketConnected;

  /// Indica si la conexión al WebSocket está activa
  final Set<String> favoriteSymbols;

  /// Conjunto de símbolos marcados como favoritos por el usuario
  final bool showFavorites;

  /// Si es true, la UI mostrará solo las criptos favoritas

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
