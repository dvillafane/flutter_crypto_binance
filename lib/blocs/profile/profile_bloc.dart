// profile_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileBloc({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<SendVerificationEmail>(_onSendVerificationEmail);
    on<SendPasswordResetEmail>(_onSendPasswordResetEmail);
    on<DeleteAccount>(_onDeleteAccount);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ProfileError('No hay usuario autenticado'));
        return;
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        emit(const ProfileError('No se encontró información del usuario'));
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] ?? 'Sin nombre';
      final email = user.email ?? 'Sin email';
      final photoUrl = user.photoURL;
      final isEmailVerified = user.emailVerified;
      emit(ProfileLoaded(
        name: name,
        email: email,
        photoUrl: photoUrl,
        isEmailVerified: isEmailVerified,
      ));
    } catch (e) {
      emit(ProfileError('Error al cargar el perfil: $e'));
    }
  }

  Future<void> _onSendVerificationEmail(SendVerificationEmail event, Emitter<ProfileState> emit) async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      emit(ProfileError('Error al enviar email de verificación: $e'));
    }
  }

  Future<void> _onSendPasswordResetEmail(SendPasswordResetEmail event, Emitter<ProfileState> emit) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _auth.sendPasswordResetEmail(email: user.email!);
      }
    } catch (e) {
      emit(ProfileError('Error al enviar email de restablecimiento: $e'));
    }
  }

  Future<void> _onDeleteAccount(DeleteAccount event, Emitter<ProfileState> emit) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      emit(ProfileError('Error al eliminar la cuenta: $e'));
    }
  }
}