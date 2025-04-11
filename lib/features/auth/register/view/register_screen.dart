import 'package:flutter/material.dart'; // Importa el paquete de Material Design de Flutter.
import 'package:flutter_bloc/flutter_bloc.dart'; // Importa flutter_bloc para manejo de estados con BLoC.
import '../bloc/register_bloc.dart'; // Importa el BLoC para el registro.
import '../../login/view/login_screen.dart'; // Importa la pantalla de login para redirección posterior.

/// Página principal de registro que provee el RegisterBloc a sus hijos.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provee el RegisterBloc a los widgets hijos.
    return BlocProvider(
      create: (_) => RegisterBloc(),
      child: const RegisterView(),
    );
  }
}

/// Widget con estado que representa la vista de registro.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

/// Estado de la vista de registro.
class _RegisterViewState extends State<RegisterView> {
  // Clave para validar el formulario.
  final _formKey = GlobalKey<FormState>();
  // Variables para almacenar los datos ingresados.
  String _email = '';
  String _password = '';
  String _name = '';

  // Colores y estilos para la interfaz.
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    // Obtiene el ancho de la pantalla.
    final screenWidth = MediaQuery.of(context).size.width;
    // Define un ancho máximo para el contenido, para diseño responsivo.
    final maxContentWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: backgroundColor, // Fondo oscuro para la pantalla.
      appBar: AppBar(
        backgroundColor: backgroundColor, // AppBar con el mismo color de fondo.
        elevation: 0, // Sin sombra en la AppBar.
        // Botón para regresar a la pantalla anterior.
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _RegisterViewState.textColor,
          ),
          onPressed: () => Navigator.pop(context), // Navega hacia atrás.
        ),
      ),
      // Escucha los cambios del RegisterBloc para reaccionar a eventos.
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterFailure) {
            // Si ocurre un error en el registro, muestra un SnackBar con el error.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is RegisterSuccess) {
            // Si el registro es exitoso, muestra un mensaje y redirige a la pantalla de login.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registro exitoso. Por favor verifica tu correo.',
                ),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
        child: SafeArea(
          // SafeArea evita que el contenido se superponga a zonas no seguras (notch, barra de estado).
          child: Center(
            // Centra el contenido horizontalmente.
            child: SingleChildScrollView(
              // Permite desplazarse si el contenido sobrepasa la altura de la pantalla.
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                // Limita el ancho máximo del contenido para diseño responsivo.
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // Espaciado superior.
                    const Text(
                      'Crea tu cuenta', // Título principal.
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _RegisterViewState.textColor,
                      ),
                    ),
                    const SizedBox(height: 10), // Espaciado entre título y subtítulo.
                    const Text(
                      'Regístrate para comenzar', // Subtítulo.
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30), // Espaciado antes del formulario.
                    Card(
                      // Tarjeta que contiene el formulario.
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Bordes redondeados.
                      ),
                      elevation: 4, // Sombra de la tarjeta.
                      child: Padding(
                        padding: const EdgeInsets.all(20), // Espaciado interno.
                        child: Form(
                          key: _formKey, // Clave para validar el formulario.
                          child: Column(
                            children: [
                              // Campo para ingresar el nombre.
                              _NameInput(
                                onSaved: (value) => _name = value!.trim(),
                              ),
                              const SizedBox(height: 20), // Espaciado entre campos.
                              // Campo para ingresar el correo electrónico.
                              _EmailInput(
                                onSaved: (value) => _email = value!.trim(),
                              ),
                              const SizedBox(height: 20), // Espaciado entre campos.
                              // Campo para ingresar la contraseña.
                              _PasswordInput(
                                onSaved: (value) => _password = value!,
                              ),
                              const SizedBox(height: 30), // Espaciado antes del botón de registro.
                              BlocBuilder<RegisterBloc, RegisterState>(
                                // BlocBuilder para reconstruir el botón según el estado.
                                builder: (context, state) {
                                  return _RegisterButton(
                                    isLoading: state is RegisterLoading,
                                    onPressed: () {
                                      // Valida el formulario y, si es válido, guarda los datos y envía el evento de registro.
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        context.read<RegisterBloc>().add(
                                          RegisterSubmitted(
                                            email: _email,
                                            password: _password,
                                            name: _name,
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
                    const SizedBox(height: 20), // Espaciado entre el formulario y el botón de login.
                    TextButton(
                      // Botón para volver a la pantalla de login.
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
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

/// Widget para el campo de entrada del nombre.
class _NameInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved; // Callback para guardar el valor ingresado.
  const _NameInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: _RegisterViewState.textColor),
      decoration: InputDecoration(
        labelText: 'Nombre', // Etiqueta del campo.
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent, // Fondo transparente.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Bordes redondeados.
          borderSide: const BorderSide(color: _RegisterViewState.accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _RegisterViewState.accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _RegisterViewState.textColor),
        ),
      ),
      // Valida que el campo no esté vacío.
      validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
      onSaved: onSaved, // Guarda el valor ingresado.
    );
  }
}

/// Widget para el campo de entrada del correo electrónico.
class _EmailInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved; // Callback para guardar el valor ingresado.
  const _EmailInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: _RegisterViewState.textColor),
      decoration: InputDecoration(
        labelText: 'Correo electrónico', // Etiqueta del campo.
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent, // Fondo transparente.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Bordes redondeados.
          borderSide: const BorderSide(color: _RegisterViewState.accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _RegisterViewState.accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _RegisterViewState.textColor),
        ),
      ),
      keyboardType: TextInputType.emailAddress, // Teclado específico para email.
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obligatorio'; // Valida que no esté vacío.
        if (!value.contains('@')) return 'Correo inválido'; // Valida formato de correo.
        return null;
      },
      onSaved: onSaved, // Guarda el valor ingresado.
    );
  }
}

/// Widget para el campo de entrada de la contraseña.
class _PasswordInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved; // Callback para guardar el valor ingresado.
  const _PasswordInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: _RegisterViewState.textColor),
      decoration: InputDecoration(
        labelText: 'Contraseña', // Etiqueta del campo.
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent, // Fondo transparente.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Bordes redondeados.
          borderSide: const BorderSide(color: _RegisterViewState.accentColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _RegisterViewState.accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _RegisterViewState.textColor),
        ),
      ),
      obscureText: true, // Oculta el texto para la contraseña.
      validator: (value) {
        // Valida que la contraseña tenga al menos 6 caracteres.
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
        return null;
      },
      onSaved: onSaved, // Guarda el valor ingresado.
    );
  }
}

/// Widget para el botón de registro.
class _RegisterButton extends StatelessWidget {
  final bool isLoading; // Indica si el proceso de registro está cargando.
  final VoidCallback onPressed; // Callback para cuando se presiona el botón.

  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      // AnimatedSwitcher para animar la transición entre estado de carga y no carga.
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity, // Botón de ancho completo.
        child: ElevatedButton(
          key: ValueKey(isLoading), // Clave para identificar la animación.
          style: ElevatedButton.styleFrom(
            backgroundColor: _RegisterViewState.accentColor, // Color de fondo del botón.
            padding: const EdgeInsets.symmetric(vertical: 15), // Padding vertical.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados.
            ),
            elevation: 2, // Sombra del botón.
          ),
          onPressed: isLoading ? null : onPressed, // Desactiva el botón si está cargando.
          child: isLoading
              ? const CircularProgressIndicator(
                  color: _RegisterViewState.textColor, // Indicador de carga.
                )
              : const Text(
                  'Registrarse', // Texto del botón en estado normal.
                  style: TextStyle(
                    color: _RegisterViewState.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
