// blocs/crypto_detail_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/crypto_detail.dart';
import '../services/crypto_detail_service.dart';

abstract class CryptoDetailEvent extends Equatable {
  const CryptoDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadCryptoDetail extends CryptoDetailEvent {
  final String assetId;

  const LoadCryptoDetail({required this.assetId});

  @override
  List<Object?> get props => [assetId];
}

abstract class CryptoDetailState extends Equatable {
  const CryptoDetailState();

  @override
  List<Object?> get props => [];
}

class CryptoDetailLoading extends CryptoDetailState {
  const CryptoDetailLoading();
}

class CryptoDetailLoaded extends CryptoDetailState {
  final CryptoDetail detail;

  const CryptoDetailLoaded({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class CryptoDetailError extends CryptoDetailState {
  final String message;

  const CryptoDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CryptoDetailBloc extends Bloc<CryptoDetailEvent, CryptoDetailState> {
  final CryptoDetailService _detailService;

  CryptoDetailBloc({required CryptoDetailService detailService})
      : _detailService = detailService,
        super(const CryptoDetailLoading()) {
    on<LoadCryptoDetail>(_onLoadCryptoDetail);
  }

  Future<void> _onLoadCryptoDetail(
      LoadCryptoDetail event, Emitter<CryptoDetailState> emit) async {
    emit(const CryptoDetailLoading());
    try {
      final detail = await _detailService.fetchCryptoDetail(event.assetId);
      emit(CryptoDetailLoaded(detail: detail));
    } catch (e) {
      emit(CryptoDetailError(message: e.toString()));
    }
  }
}
