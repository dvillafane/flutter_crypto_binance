// Importaciones necesarias para construir la UI y manejar el estado con BLoC
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importaciones de pantallas personalizadas
import 'package:flutter_crypto_binance/screens/home_screen.dart';
import 'package:flutter_crypto_binance/screens/auth_screen/register_screen.dart';
import 'package:sign_button/sign_button.dart'; // Botón de inicio de sesión con Google
import 'forgot_password_screen.dart';
import '../../blocs/login/login_bloc.dart'; // BLoC para manejar el estado del login

// Pantalla principal de inicio de sesión sin estado
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provee el LoginBloc a la siguiente vista
    return BlocProvider(
      create: (_) => LoginBloc(), // Se crea una instancia del bloc
      child: const LoginView(), // Se muestra la vista de login
    );
  }
}

// Vista del login con estado
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState(); // Crea el estado asociado
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  String _email = ''; // Variable para guardar el correo
  String _password = ''; // Variable para guardar la contraseña

  static const backgroundColor = Color(0xFF121212); // Color de fondo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Color oscuro de fondo
      // Escucha los cambios de estado del LoginBloc
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            // Muestra un mensaje de error si falla el login
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is LoginSuccess) {
            // Redirige a la pantalla principal si el login es exitoso
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },

        // Vista principal centrada con scroll
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo de la app
                Image.asset(
                  'assets/icon/app_icon_removebg.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),

                // Formulario con campos de email y contraseña
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Campo para email
                      _EmailInput(onSaved: (value) => _email = value!.trim()),
                      const SizedBox(height: 20),

                      // Campo para contraseña
                      _PasswordInput(onSaved: (value) => _password = value!),
                      const SizedBox(height: 20),

                      // Botón de login que cambia según el estado del Bloc
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          return _LoginButton(
                            isLoading:
                                state
                                    is LoginLoading, // Muestra loader si está cargando
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!
                                    .save(); // Guarda los datos del form
                                context.read<LoginBloc>().add(
                                  LoginSubmitted(
                                    email: _email,
                                    password: _password,
                                  ),
                                ); // Envía evento al Bloc
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botón para ir a recuperar contraseña
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    '¿Has olvidado la contraseña?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 40),

                // Botón para ir a la pantalla de registro
                _CreateAccountButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPage()),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Botón para login con Google
                SignInButton(
                  buttonType: ButtonType.google,
                  onPressed: () {
                    context.read<LoginBloc>().add(
                      LoginGoogleSubmitted(),
                    ); // Evento de login con Google
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Colores personalizados
const cardColor = Color(0xFF1E1E1E);
const accentColor = Color.fromRGBO(66, 66, 66, 1);
const textColor = Colors.white;

// Widget para campo de texto del email
class _EmailInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved;
  const _EmailInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: textColor), // Texto blanco
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor, // Fondo del input
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.emailAddress, // Tipo de teclado
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo obligatorio';
        if (!value!.contains('@')) return 'Email inválido';
        return null;
      },
      onSaved: onSaved,
    );
  }
}

// Widget para campo de contraseña
class _PasswordInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved;
  const _PasswordInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: textColor), // Texto blanco
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      obscureText: true, // Oculta el texto para seguridad
      validator: (value) => value?.isEmpty ?? true ? 'Campo obligatorio' : null,
      onSaved: onSaved,
    );
  }
}

// Botón de iniciar sesión
class _LoginButton extends StatelessWidget {
  final bool isLoading; // Indica si está cargando
  final VoidCallback onPressed; // Acción al presionar

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Toma todo el ancho posible
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isLoading ? null : onPressed, // Desactiva si está cargando
        child:
            isLoading
                ? const CircularProgressIndicator(
                  color: Colors.white,
                ) // Muestra spinner
                : const Text(
                  'Iniciar sesión',
                  style: TextStyle(color: Colors.white),
                ),
      ),
    );
  }
}

// Botón para crear cuenta nueva
class _CreateAccountButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateAccountButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: accentColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: const Text(
        'Crear cuenta nueva',
        style: TextStyle(color: accentColor),
      ),
    );
  }
}
