import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  RegisterBloc({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    final email = event.email.trim();
    final password = event.password;
    final name = event.name.trim();

    if (password.length < 6) {
      emit(const RegisterFailure('La contraseña debe tener al menos 6 caracteres'));
      return;
    }
    if (name.isEmpty) {
      emit(const RegisterFailure('El nombre es obligatorio'));
      return;
    }

    emit(RegisterLoading());
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        // Guardar el nombre en Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
        });
        await user.sendEmailVerification();
        emit(RegisterSuccess());
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Error en el registro';
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'El correo electrónico ya está en uso';
          break;
        case 'invalid-email':
          errorMsg = 'Formato de email inválido';
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