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
  String _name = ''; // Nuevo campo para el nombre

  // Colores y estilos para la interfaz
  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Fondo oscuro
      appBar: AppBar(
        backgroundColor: backgroundColor, // AppBar con el mismo fondo
        elevation: 0,
        // Botón para regresar a la pantalla anterior
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Escucha los cambios del RegisterBloc para reaccionar a eventos de éxito o error
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterFailure) {
            // Muestra un mensaje en caso de error en el registro
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is RegisterSuccess) {
            // Muestra un mensaje de éxito y redirige a la pantalla de login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registro exitoso. Por favor verifica tu correo.'),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la pantalla
                const Text(
                  'Crea una cuenta nueva',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 30),
                // Formulario de registro
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Campo para el nombre
                      _NameInput(onSaved: (value) => _name = value!.trim()),
                      const SizedBox(height: 20),
                      // Campo para el correo electrónico
                      _EmailInput(onSaved: (value) => _email = value!.trim()),
                      const SizedBox(height: 20),
                      // Campo para la contraseña
                      _PasswordInput(onSaved: (value) => _password = value!),
                      const SizedBox(height: 20),
                      // Botón de registro con indicador de carga
                      BlocBuilder<RegisterBloc, RegisterState>(
                        builder: (context, state) {
                          return _RegisterButton(
                            isLoading: state is RegisterLoading,
                            onPressed: () {
                              // Valida el formulario y guarda los datos
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                // Envia el evento de registro con los datos
                                context.read<RegisterBloc>().add(
                                  RegisterSubmitted(
                                    email: _email,
                                    password: _password,
                                    name: _name, // Se envía también el nombre
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
              ],
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
      // Estilo del texto
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _RegisterViewState.cardColor, // Color de fondo del campo
        labelText: 'Nombre', // Etiqueta del campo
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        // Valida que el nombre no esté vacío
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        return null;
      },
      onSaved: onSaved, // Guarda el valor ingresado en _name
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _RegisterViewState.cardColor,
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        // Verifica que el campo no esté vacío y contenga un '@'
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if (!value.contains('@')) return 'Correo inválido';
        return null;
      },
      onSaved: onSaved, // Guarda el valor ingresado en _email
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _RegisterViewState.cardColor,
        labelText: 'Contraseña',
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      obscureText: true, // Oculta el texto para la contraseña
      validator: (value) {
        // Valida que la contraseña tenga al menos 6 caracteres
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
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
    return SizedBox(
      width: double.infinity, // Botón de ancho completo
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _RegisterViewState.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Deshabilita el botón si está en proceso de registro
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Registrarse',
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}
