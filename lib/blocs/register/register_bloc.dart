import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final FirebaseAuth _auth;
  RegisterBloc({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      await userCredential.user!.sendEmailVerification();
      emit(RegisterSuccess());
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'El correo electrónico ya está en uso';
          break;
        case 'invalid-email':
          errorMsg = 'Formato de email inválido';
          break;
        case 'operation-not-allowed':
          errorMsg = 'Operación no permitida';
          break;
        case 'weak-password':
          errorMsg = 'Contraseña débil';
          break;
        default:
          errorMsg = 'Error en el registro';
      }
      emit(RegisterFailure(errorMsg));
    } catch (e) {
      emit(RegisterFailure('Error desconocido: ${e.toString()}'));
    }
  }
}
