import 'package:equatable/equatable.dart';

/// ----------------------------
/// 1. DEFINICIÓN DE EVENTOS
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

class ChangeSortCriteria extends CryptoEvent {
  final String criteria;
  const ChangeSortCriteria(this.criteria);
  @override
  List<Object?> get props => [criteria];
}
