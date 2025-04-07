// profile_state.dart
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final String name;
  final String email;
  final String? photoUrl;
  final bool isEmailVerified;

  const ProfileLoaded({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.isEmailVerified,
  });

  @override
  List<Object> get props => [name, email, photoUrl ?? '', isEmailVerified];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}