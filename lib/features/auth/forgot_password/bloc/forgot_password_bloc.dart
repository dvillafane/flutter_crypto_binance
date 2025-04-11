import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc() : super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty) {
      emit(
        const ForgotPasswordFailure("Por favor ingresa un correo electrónico"),
      );
      return;
    }
    emit(ForgotPasswordLoading());
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emit(
        const ForgotPasswordSuccess(
          "Se ha enviado un enlace de recuperación a tu correo",
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'invalid-email':
          errorMsg = 'El formato del email es inválido';
          break;
        case 'user-not-found':
          errorMsg = 'No se encontró un usuario con este email';
          break;
        default:
          errorMsg = 'Error al enviar el email de recuperación';
      }
      emit(ForgotPasswordFailure(errorMsg));
    } catch (e) {
      emit(ForgotPasswordFailure('Error desconocido: ${e.toString()}'));
    }
  }
}
