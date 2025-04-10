// Importa el paquete principal de Flutter para los widgets Material.
import 'package:flutter/material.dart';
// Importa Flutter Bloc para el manejo del estado con el patrón Bloc.
import 'package:flutter_bloc/flutter_bloc.dart';
// Importa la pantalla de inicio (HomeScreen) para navegación tras login exitoso.
import 'package:flutter_crypto_binance/screens/home_screen.dart';
// Importa la pantalla de registro para crear una cuenta.
import 'package:flutter_crypto_binance/screens/auth_screen/register_screen.dart';
// Importa un botón diseñado para iniciar sesión con Google.
import 'package:sign_button/sign_button.dart'; // Botón de inicio de sesión con Google.
// Importa la pantalla para recuperar la contraseña.
import 'forgot_password_screen.dart';
// Importa el Bloc de login para gestionar eventos y estados durante el proceso de inicio de sesión.
import '../../blocs/login/login_bloc.dart'; // BLoC para manejar el estado del login

// Clase principal de la pantalla de login sin estado (StatelessWidget)
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Se utiliza BlocProvider para proveer una instancia del LoginBloc a sus hijos.
    return BlocProvider(
      create: (_) => LoginBloc(), // Crea una instancia del LoginBloc
      child: const LoginView(), // Muestra la vista del login que es con estado
    );
  }
}

// Vista del login implementada como StatefulWidget para poder manejar estados internos.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState(); // Crea el estado asociado a esta vista.
}

// Clase de estado de la vista de login.
class _LoginViewState extends State<LoginView> {
  // Llave global para el formulario, necesaria para la validación y manejo del estado.
  final _formKey = GlobalKey<FormState>();
  // Variables para almacenar el correo y contraseña ingresados.
  String _email = '';
  String _password = '';

  // Definición de colores de fondo y de tarjetas para mantener la consistencia en el tema.
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    // Obtiene el ancho de la pantalla para ajustar el contenido de forma responsiva.
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: backgroundColor, // Fondo oscuro de la pantalla.
      // BlocListener para reaccionar a los cambios de estado del LoginBloc.
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            // Si falla el login, se muestra un SnackBar con el mensaje de error.
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is LoginSuccess) {
            // Si el login es exitoso, se redirige a la pantalla principal y se elimina el historial de navegación.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
        child: SafeArea(
          child: Center(
            // ConstrainedBox limita el ancho máximo del contenido para pantallas más grandes.
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics:
                    const ClampingScrollPhysics(), // Evita scroll innecesario.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Muestra el logo de la aplicación.
                    Image.asset(
                      'assets/icon/app_icon_removebg.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 15),
                    // Título de bienvenida.
                    const Text(
                      'Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Texto indicativo para iniciar sesión.
                    const Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta que contiene el formulario de login.
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        // Formulario que contiene los campos de email y contraseña.
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Widget personalizado para el input del correo electrónico.
                              _EmailInput(
                                onSaved: (value) => _email = value!.trim(),
                              ),
                              const SizedBox(height: 15),
                              // Widget personalizado para el input de la contraseña.
                              _PasswordInput(
                                onSaved: (value) => _password = value!,
                              ),
                              const SizedBox(height: 15),
                              // Bloque que reconstruye el botón de login en función del estado del Bloc.
                              BlocBuilder<LoginBloc, LoginState>(
                                builder: (context, state) {
                                  return _LoginButton(
                                    isLoading:
                                        state
                                            is LoginLoading, // Deshabilita el botón si se está cargando.
                                    onPressed: () {
                                      // Valida el formulario.
                                      if (_formKey.currentState!.validate()) {
                                        // Guarda el estado actual de los campos del formulario.
                                        _formKey.currentState!.save();
                                        // Envía el evento de login con los datos ingresados al Bloc.
                                        context.read<LoginBloc>().add(
                                          LoginSubmitted(
                                            email: _email,
                                            password: _password,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Enlace para recuperar contraseña.
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // Navega a la pantalla de "Olvidé mi contraseña".
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Has olvidado la contraseña?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),

                    // Botón para crear cuenta nueva.
                    const SizedBox(height: 20),
                    _CreateAccountButton(
                      onPressed: () {
                        // Navega a la pantalla de registro.
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Botón para acceder como invitado.
                    _GuestButton(
                      onPressed: () {
                        // Navega a la pantalla principal sin requerir login.
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(isGuest: true),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Botón para iniciar sesión con Google utilizando el paquete sign_button.
                    SignInButton(
                      buttonType: ButtonType.google,
                      btnColor: cardColor,
                      btnTextColor: Colors.white,
                      elevation: 2,
                      padding: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onPressed: () {
                        // Envía el evento para iniciar sesión con Google al Bloc.
                        context.read<LoginBloc>().add(LoginGoogleSubmitted());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget personalizado para el input del correo electrónico.
class _EmailInput extends StatelessWidget {
  final FormFieldSetter<String>
  onSaved; // Callback para guardar el valor ingresado.
  const _EmailInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromRGBO(66, 66, 66, 1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromRGBO(66, 66, 66, 1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo obligatorio';
        if (!value!.contains('@')) return 'Email inválido';
        return null;
      },
      onSaved: onSaved, // Llama al callback pasado en el constructor.
    );
  }
}

// Widget personalizado para el input de la contraseña.
class _PasswordInput extends StatelessWidget {
  final FormFieldSetter<String>
  onSaved; // Callback para guardar el valor ingresado.
  const _PasswordInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromRGBO(66, 66, 66, 1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromRGBO(66, 66, 66, 1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      obscureText: true, // Oculta el texto para la contraseña.
      validator: (value) => value?.isEmpty ?? true ? 'Campo obligatorio' : null,
      onSaved: onSaved, // Llama al callback pasado en el constructor.
    );
  }
}

// Widget para el botón de iniciar sesión, con estado de carga.
class _LoginButton extends StatelessWidget {
  final bool
  isLoading; // Indica si se encuentra en proceso de login para mostrar un indicador.
  final VoidCallback
  onPressed; // Callback que se ejecuta al presionar el botón.

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(66, 66, 66, 1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        // Si está cargando, se deshabilita el botón.
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? const CircularProgressIndicator(
                  color: Colors.white,
                ) // Indicador de carga.
                : const Text(
                  'Iniciar sesión',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
      ),
    );
  }
}

// Widget para el botón de "Crear cuenta nueva".
class _CreateAccountButton extends StatelessWidget {
  final VoidCallback
  onPressed; // Callback que se ejecuta al presionar el botón.
  const _CreateAccountButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: const Text(
          'Crear cuenta nueva',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}

// Widget para el botón de "Entrar como invitado".
class _GuestButton extends StatelessWidget {
  final VoidCallback
  onPressed; // Callback que se ejecuta al presionar el botón.
  const _GuestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF424242)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: const Text(
          'Entrar como invitado',
          style: TextStyle(color: Color(0xFF424242), fontSize: 16),
        ),
      ),
    );
  }
}
