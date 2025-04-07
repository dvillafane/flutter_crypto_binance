import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth;
  LoginBloc({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginGoogleSubmitted>(_onLoginGoogleSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final email = event.email.trim();
    final password = event.password;
    emit(LoginLoading());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user?.emailVerified ?? false) {
        emit(LoginSuccess());
      } else {
        emit(const LoginFailure("Por favor verifica tu correo electrónico"));
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          errorMsg = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMsg = 'Formato de email inválido';
          break;
        case 'user-disabled':
          errorMsg = 'Cuenta deshabilitada';
          break;
        case 'too-many-requests':
          errorMsg = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          errorMsg = 'Error de autenticación';
      }
      emit(LoginFailure(errorMsg));
    } catch (e) {
      emit(LoginFailure('Error desconocido: ${e.toString()}'));
    }
  }

  Future<void> _onLoginGoogleSubmitted(
    LoginGoogleSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(const LoginFailure("Inicio de sesión con Google cancelado"));
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      emit(LoginSuccess());
    } on FirebaseAuthException catch (e) {
      emit(LoginFailure('Error en autenticación con Google: ${e.message}'));
    } catch (e) {
      emit(LoginFailure('Error desconocido: ${e.toString()}'));
    }
  }
}
