// Importa los paquetes necesarios de Flutter y otros módulos
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_crypto_binance/blocs/profile/profile_bloc.dart';
import 'package:flutter_crypto_binance/blocs/profile/profile_event.dart';
import 'package:flutter_crypto_binance/blocs/profile/profile_state.dart';
import 'package:flutter_crypto_binance/screens/auth_screen/login_screen.dart';

// Widget sin estado para mostrar el perfil del usuario
class ProfileScreen extends StatelessWidget {
  // Indica si el usuario es invitado
  final bool isGuest;
  const ProfileScreen({super.key, this.isGuest = false});

  // Colores utilizados en la interfaz
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;
  static const hintColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    // Provee el bloc de perfil e inicia el evento LoadProfile al construir
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfile()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu perfil'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: backgroundColor,
        // Usa BlocConsumer para manejar estados del bloc
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            // Muestra errores solo si el usuario no es invitado
            if (state is ProfileError && !isGuest) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            // Si el usuario es invitado, muestra mensaje e invita a iniciar sesión
            if (isGuest) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Inicia sesión para ver tu perfil',
                      style: TextStyle(color: textColor, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navega a la pantalla de login y elimina el historial
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Si el estado es cargando, muestra un indicador de progreso
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Si los datos del perfil fueron cargados correctamente
            else if (state is ProfileLoaded) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Contenedor con información visual del perfil
                    Container(
                      color: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Muestra el avatar del usuario
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
                                // Icono de cámara sobre el avatar
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
                            // Muestra el nombre del usuario
                            Text(
                              state.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Muestra el correo del usuario
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
                    // Opciones del perfil: ajustes y cerrar sesión
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Tarjeta con opciones de ajustes
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
                                // Opción para restablecer contraseña
                                ListTile(
                                  title: const Text(
                                    'Restablecer contraseña',
                                    style: TextStyle(color: textColor),
                                  ),
                                  onTap: () {
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
                                // Opción para eliminar cuenta con confirmación
                                ListTile(
                                  title: const Text(
                                    'Eliminar cuenta',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                  onTap: () async {
                                    // Muestra un diálogo para confirmar eliminación
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
                                              // Botón para cancelar
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
                                              // Botón para confirmar eliminación
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

                                    // Si el usuario confirmó, elimina cuenta y navega a login
                                    if (shouldDelete == true &&
                                        context.mounted) {
                                      context.read<ProfileBloc>().add(
                                        DeleteAccount(),
                                      );
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
                          // Tarjeta para cerrar sesión
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
                                // Cierra la sesión de Firebase y navega a login
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
            // Si ocurre un error, muestra el mensaje correspondiente
            else if (state is ProfileError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: textColor, fontSize: 18),
                ),
              );
            }
            // Estado por defecto antes de iniciar
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
