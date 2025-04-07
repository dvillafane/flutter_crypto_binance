// profile_event.dart
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {}

class SendVerificationEmail extends ProfileEvent {}

class SendPasswordResetEmail extends ProfileEvent {}

class DeleteAccount extends ProfileEvent {}