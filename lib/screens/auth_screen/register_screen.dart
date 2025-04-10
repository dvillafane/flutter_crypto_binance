import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/register/register_bloc.dart';
import 'login_screen.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provee el RegisterBloc a los widgets hijos
    return BlocProvider(
      create: (_) => RegisterBloc(),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();
  // Variables para almacenar los datos ingresados
  String _email = '';
  String _password = '';
  String _name = '';

  // Colores y estilos para la interfaz
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: backgroundColor, // Fondo oscuro
      appBar: AppBar(
        backgroundColor: backgroundColor, // AppBar con el mismo fondo
        elevation: 0,
        // Botón para regresar a la pantalla anterior
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _RegisterViewState.textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Escucha los cambios del RegisterBloc para reaccionar a eventos de éxito o error
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterFailure) {
            // Muestra un mensaje en caso de error en el registro
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is RegisterSuccess) {
            // Muestra un mensaje de éxito y redirige a la pantalla de login
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Crea tu cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _RegisterViewState.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Regístrate para comenzar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _NameInput(
                                onSaved: (value) => _name = value!.trim(),
                              ),
                              const SizedBox(height: 20),
                              _EmailInput(
                                onSaved: (value) => _email = value!.trim(),
                              ),
                              const SizedBox(height: 20),
                              _PasswordInput(
                                onSaved: (value) => _password = value!,
                              ),
                              const SizedBox(height: 30),
                              BlocBuilder<RegisterBloc, RegisterState>(
                                builder: (context, state) {
                                  return _RegisterButton(
                                    isLoading: state is RegisterLoading,
                                    onPressed: () {
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
                    const SizedBox(height: 20),
                    TextButton(
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

// Widget para el campo de entrada del nombre
class _NameInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved;
  const _NameInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: _RegisterViewState.textColor),
      decoration: InputDecoration(
        labelText: 'Nombre',
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
      validator:
          (value) =>
              value == null || value.isEmpty ? 'Campo obligatorio' : null,
      onSaved: onSaved,
    );
  }
}

// Widget para el campo de entrada del correo electrónico
class _EmailInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved;
  const _EmailInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: _RegisterViewState.textColor),
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if (!value.contains('@')) return 'Correo inválido';
        return null;
      },
      onSaved: onSaved,
    );
  }
}

// Widget para el campo de entrada de la contraseña
class _PasswordInput extends StatelessWidget {
  final FormFieldSetter<String> onSaved;
  const _PasswordInput({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: _RegisterViewState.textColor),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
      obscureText: true,
      validator: (value) {
        // Valida que la contraseña tenga al menos 6 caracteres
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
        return null;
      },
      onSaved: onSaved, // Guarda el valor ingresado en _password
    );
  }
}

// Widget para el botón de registro
class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: ValueKey(isLoading),
          style: ElevatedButton.styleFrom(
            backgroundColor: _RegisterViewState.accentColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          onPressed: isLoading ? null : onPressed,
          child:
              isLoading
                  ? const CircularProgressIndicator(
                    color: _RegisterViewState.textColor,
                  )
                  : const Text(
                    'Registrarse',
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
