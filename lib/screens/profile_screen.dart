// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_crypto_binance/blocs/profile/profile_bloc.dart';
import 'package:flutter_crypto_binance/blocs/profile/profile_event.dart';
import 'package:flutter_crypto_binance/blocs/profile/profile_state.dart';
import 'package:flutter_crypto_binance/screens/auth_screen/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;
  static const hintColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfile()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad de edición en desarrollo')),
                );
              },
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProfileLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: state.photoUrl != null ? NetworkImage(state.photoUrl!) : null,
                      backgroundColor: cardColor,
                      child: state.photoUrl == null
                          ? const Icon(Icons.person, size: 60, color: textColor)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      state.email,
                      style: const TextStyle(fontSize: 18, color: hintColor),
                    ),
                    const SizedBox(height: 10),
                    if (!state.isEmailVerified) ...[
                      Text(
                        'Email no verificado',
                        style: TextStyle(color: Colors.redAccent.shade100, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 30),
                    _buildActionButton(
                      context: context,
                      label: state.isEmailVerified ? 'Email verificado' : 'Verificar email',
                      icon: Icons.email,
                      onPressed: state.isEmailVerified
                          ? null
                          : () {
                              context.read<ProfileBloc>().add(SendVerificationEmail());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Email de verificación enviado')),
                              );
                            },
                      color: state.isEmailVerified ? hintColor : accentColor,
                    ),
                    const SizedBox(height: 15),
                    _buildActionButton(
                      context: context,
                      label: 'Restablecer contraseña',
                      icon: Icons.lock,
                      onPressed: () {
                        context.read<ProfileBloc>().add(SendPasswordResetEmail());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email de recuperación enviado')),
                        );
                      },
                      color: accentColor,
                    ),
                    const SizedBox(height: 15),
                    _buildActionButton(
                      context: context,
                      label: 'Cerrar sesión',
                      icon: Icons.exit_to_app,
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 15),
                    _buildActionButton(
                      context: context,
                      label: 'Eliminar cuenta',
                      icon: Icons.delete_forever,
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar cuenta', style: TextStyle(color: textColor)),
                            content: const Text(
                              '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer.',
                              style: TextStyle(color: textColor),
                            ),
                            backgroundColor: cardColor,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar', style: TextStyle(color: accentColor)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          context.read<ProfileBloc>().add(DeleteAccount());
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      color: Colors.redAccent.shade700,
                    ),
                  ],
                ),
              );
            } else if (state is ProfileError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: textColor, fontSize: 18),
                ),
              );
            }
            return const Center(
              child: Text(
                'Estado inicial',
                style: TextStyle(color: textColor, fontSize: 18),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: const TextStyle(color: textColor, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}