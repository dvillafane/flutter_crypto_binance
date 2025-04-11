import 'package:flutter/material.dart'; // Importación del paquete de material design de Flutter.
import 'package:flutter_bloc/flutter_bloc.dart'; // Importación del paquete flutter_bloc para manejo de estados con BLoC.
import '../bloc/forgot_password_bloc.dart'; // Importa el BLoC específico para recuperación de contraseña.
import '../../login/view/login_screen.dart'; // Importa la pantalla de login para redirección después de enviar el código.

/// Widget principal de la pantalla de "Forgot Password".
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// Estado asociado a [ForgotPasswordScreen].
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controlador para el campo de texto del correo electrónico.
  final TextEditingController emailController = TextEditingController();

  // Constantes de colores para la interfaz.
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;
  static const hintColor = Colors.grey;

  @override
  void dispose() {
    // Libera el controlador cuando se destruya el widget.
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el ancho de la pantalla para un diseño responsivo.
    final screenWidth = MediaQuery.of(context).size.width;
    // Establece un ancho máximo para el contenido: 400 si la pantalla es ancha, o el 90% del ancho en pantallas pequeñas.
    final maxContentWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

    return BlocProvider(
      // Provee la instancia de ForgotPasswordBloc a los widgets hijos.
      create: (_) => ForgotPasswordBloc(),
      child: Scaffold(
        backgroundColor: backgroundColor, // Establece el color de fondo de la pantalla.
        appBar: AppBar(
          backgroundColor: backgroundColor, // AppBar con el mismo color de fondo.
          elevation: 0, // Elimina la sombra de la AppBar.
          leading: IconButton(
            // Botón para regresar a la pantalla anterior.
            icon: const Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context), // Acción para cerrar la pantalla actual.
          ),
        ),
        body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
          // Escucha los cambios de estado del ForgotPasswordBloc.
          listener: (context, state) async {
            if (state is ForgotPasswordSuccess) {
              // Si la recuperación fue exitosa:
              // Captura el ScaffoldMessenger y Navigator para evitar usar el BuildContext en un gap async.
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              // Muestra un SnackBar con el mensaje de éxito.
              messenger.showSnackBar(SnackBar(content: Text(state.message)));

              // Espera 2 segundos para permitir al usuario leer el mensaje.
              await Future.delayed(const Duration(seconds: 2));

              // Verifica que el widget siga montado antes de proceder a la navegación.
              if (!mounted) return;
              // Navega reemplazando la pantalla actual por LoginPage.
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            } else if (state is ForgotPasswordFailure) {
              // Si hay un fallo, muestra el mensaje de error en un SnackBar.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          child: SafeArea(
            // SafeArea para evitar zonas no seguras de la pantalla.
            child: LayoutBuilder(
              // LayoutBuilder para obtener restricciones y hacer el diseño responsivo.
              builder: (context, constraints) {
                return Center(
                  // Centra el contenido.
                  child: SingleChildScrollView(
                    // Permite el desplazamiento en pantallas pequeñas.
                    padding: const EdgeInsets.all(20.0), // Espaciado alrededor del contenido.
                    child: ConstrainedBox(
                      // Limita el ancho máximo del contenido.
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        // Columna para colocar los widgets en orden vertical.
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20), // Espaciado superior.
                          const Text(
                            "Recupera tu cuenta", // Título principal.
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10), // Espaciado entre título y subtítulo.
                          const Text(
                            "Ingresa tu dirección de correo electrónico para recibir instrucciones.", // Subtítulo.
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: hintColor),
                          ),
                          const SizedBox(height: 30), // Espaciado antes del Card.
                          Card(
                            // Tarjeta que contiene el formulario.
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4, // Sombra de la tarjeta.
                            child: Padding(
                              // Padding interno de la tarjeta.
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    // Campo de texto para ingresar el correo.
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      labelText: "Correo electrónico",
                                      labelStyle: const TextStyle(color: hintColor),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: accentColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: accentColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: textColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30), // Espaciado antes del botón.
                                  BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                                    // BlocBuilder para reconstruir el botón según el estado.
                                    builder: (context, state) {
                                      final isLoading = state is ForgotPasswordLoading;
                                      return AnimatedSwitcher(
                                        // AnimatedSwitcher para animar el cambio entre estados (cargando y no cargando).
                                        duration: const Duration(milliseconds: 300),
                                        child: SizedBox(
                                          key: ValueKey(isLoading), // Clave para el AnimatedSwitcher.
                                          width: double.infinity, // Botón de ancho completo.
                                          height: 50, // Alto del botón.
                                          child: ElevatedButton(
                                            // Botón para enviar las instrucciones.
                                            onPressed: isLoading
                                                ? null // Desactiva el botón si está en estado de carga.
                                                : () {
                                                    final email = emailController.text.trim();
                                                    // Verifica que el correo no esté vacío y sea válido.
                                                    if (email.isNotEmpty && email.contains('@')) {
                                                      // Envía el evento de ForgotPassword con el correo ingresado.
                                                      context.read<ForgotPasswordBloc>().add(
                                                            ForgotPasswordSubmitted(email: email),
                                                          );
                                                    } else {
                                                      // Muestra error si el correo no es válido.
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Por favor ingresa un correo válido'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: accentColor,
                                              padding: const EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: isLoading
                                                ? const CircularProgressIndicator(color: textColor)
                                                : const Text(
                                                    "Enviar instrucciones", // Texto del botón en estado normal.
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: textColor,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
