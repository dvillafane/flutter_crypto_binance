// Importa los paquetes necesarios
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Para gestión de estado con BLoC
import 'package:firebase_auth/firebase_auth.dart'; // Para autenticación con Firebase
import 'package:flutter_crypto_binance/blocs/profile/profile_bloc.dart'; // BLoC de perfil
import 'package:flutter_crypto_binance/blocs/profile/profile_event.dart'; // Eventos del BLoC
import 'package:flutter_crypto_binance/blocs/profile/profile_state.dart'; // Estados del BLoC
import 'package:flutter_crypto_binance/screens/auth_screen/login_screen.dart'; // Pantalla de login

// Pantalla principal del perfil del usuario
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Colores constantes para usar en toda la pantalla
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;
  static const hintColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Crea el BLoC e inicia cargando el perfil
      create: (context) => ProfileBloc()..add(LoadProfile()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu perfil'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: backgroundColor,
        // Escucha cambios en el estado del BLoC
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              // Muestra error si hay uno
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            // Muestra un indicador de carga mientras se obtiene el perfil
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Si el perfil fue cargado exitosamente
            else if (state is ProfileLoaded) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Encabezado con la foto y datos del usuario
                    Container(
                      color: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Muestra la foto del usuario o un ícono por defecto
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      state.photoUrl != null
                                          ? NetworkImage(state.photoUrl!)
                                          : null,
                                  backgroundColor: cardColor,
                                  child:
                                      state.photoUrl == null
                                          ? const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: textColor,
                                          )
                                          : null,
                                ),
                                // Ícono de cámara superpuesto (decorativo)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Nombre del usuario
                            Text(
                              state.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Correo del usuario
                            Text(
                              state.email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Lista de opciones del perfil
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Opción "Ajustes" con submenú expandible
                          Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ExpansionTile(
                              leading: const Icon(
                                Icons.settings,
                                color: hintColor,
                              ),
                              title: const Text(
                                'Ajustes',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                ),
                              ),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              childrenPadding: const EdgeInsets.only(
                                left: 40,
                                bottom: 8,
                              ),
                              backgroundColor: cardColor,
                              collapsedBackgroundColor: cardColor,
                              children: [
                                // Opción para restablecer la contraseña
                                ListTile(
                                  title: const Text(
                                    'Restablecer contraseña',
                                    style: TextStyle(color: textColor),
                                  ),
                                  onTap: () {
                                    // Dispara el evento para enviar el email de recuperación
                                    context.read<ProfileBloc>().add(
                                      SendPasswordResetEmail(),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Email de recuperación enviado',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Opción para eliminar cuenta
                                ListTile(
                                  title: const Text(
                                    'Eliminar cuenta',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                  onTap: () async {
                                    // Diálogo de confirmación antes de eliminar
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text(
                                              'Eliminar cuenta',
                                              style: TextStyle(
                                                color: textColor,
                                              ),
                                            ),
                                            content: const Text(
                                              '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer.',
                                              style: TextStyle(
                                                color: textColor,
                                              ),
                                            ),
                                            backgroundColor: cardColor,
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text(
                                                  'Cancelar',
                                                  style: TextStyle(
                                                    color: accentColor,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text(
                                                  'Eliminar',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );

                                    // Si el usuario confirma, se elimina la cuenta
                                    if (shouldDelete == true &&
                                        context.mounted) {
                                      context.read<ProfileBloc>().add(
                                        DeleteAccount(),
                                      );
                                      // Redirige a la pantalla de login
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const LoginPage(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Botón para cerrar sesión
                          Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.power_settings_new,
                                color: Colors.redAccent,
                              ),
                              title: const Text(
                                'Cerrar sesión',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 18,
                                ),
                              ),
                              onTap: () {
                                // Cierra la sesión y redirige al login
                                FirebaseAuth.instance.signOut();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            // Si ocurre un error de perfil
            else if (state is ProfileError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: textColor, fontSize: 18),
                ),
              );
            }

            // Estado por defecto/inicial
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
}
