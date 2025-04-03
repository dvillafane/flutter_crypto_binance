// Importa las dependencias necesarias para el uso de BLoC y la comparación de objetos.
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Importa el modelo de detalles de la criptomoneda.
import '../models/crypto_detail.dart';
// Importa el servicio que obtiene los detalles de la criptomoneda desde una API.
import '../services/crypto_detail_service.dart';

/// Definición de eventos para el BLoC de detalles de criptomonedas.
abstract class CryptoDetailEvent extends Equatable {
  const CryptoDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar los detalles de una criptomoneda específica.
class LoadCryptoDetail extends CryptoDetailEvent {
  // Identificador del activo o criptomoneda.
  final String assetId;

  // Constructor que recibe el ID del activo de forma obligatoria.
  const LoadCryptoDetail({required this.assetId});

  @override
  List<Object?> get props => [assetId];
}

/// Definición de estados para el BLoC de detalles de criptomonedas.
abstract class CryptoDetailState extends Equatable {
  const CryptoDetailState();

  @override
  List<Object?> get props => [];
}

/// Estado que indica que los detalles de la criptomoneda se están cargando.
class CryptoDetailLoading extends CryptoDetailState {
  const CryptoDetailLoading();
}

/// Estado que indica que los detalles de la criptomoneda se han cargado correctamente.
class CryptoDetailLoaded extends CryptoDetailState {
  // Objeto que contiene los detalles de la criptomoneda.
  final CryptoDetail detail;

  // Constructor que recibe el detalle de la criptomoneda de forma obligatoria.
  const CryptoDetailLoaded({required this.detail});

  @override
  List<Object?> get props => [detail];
}

/// Estado que indica que ocurrió un error al cargar los detalles de la criptomoneda.
class CryptoDetailError extends CryptoDetailState {
  // Mensaje de error que describe el problema.
  final String message;

  // Constructor que recibe el mensaje de error de forma obligatoria.
  const CryptoDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// BLoC para manejar la lógica de carga de detalles de criptomonedas.
class CryptoDetailBloc extends Bloc<CryptoDetailEvent, CryptoDetailState> {
  // Servicio que obtiene los detalles de la criptomoneda.
  final CryptoDetailService _detailService;

  /// Constructor del BLoC que inicializa el estado de carga
  /// y registra el evento para cargar detalles de la criptomoneda.
  CryptoDetailBloc({required CryptoDetailService detailService})
    : _detailService = detailService,
      super(const CryptoDetailLoading()) {
    // Registra el método que maneja el evento de carga de detalles.
    on<LoadCryptoDetail>(_onLoadCryptoDetail);
  }

  /// Método que maneja el evento de carga de detalles de la criptomoneda.
  Future<void> _onLoadCryptoDetail(
    LoadCryptoDetail event,
    Emitter<CryptoDetailState> emit,
  ) async {
    // Emitir el estado de carga mientras se obtienen los detalles.
    emit(const CryptoDetailLoading());
    try {
      // Obtener los detalles de la criptomoneda usando el servicio.
      final detail = await _detailService.fetchCryptoDetail(event.assetId);
      // Emitir el estado de éxito con los detalles obtenidos.
      emit(CryptoDetailLoaded(detail: detail));
    } catch (e) {
      // Emitir el estado de error si ocurre una excepción.
      emit(CryptoDetailError(message: e.toString()));
    }
  }
}
