import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/register/register_bloc.dart';
import 'login_screen.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
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
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is RegisterSuccess) {
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crea una cuenta nueva',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _EmailInput(onSaved: (value) => _email = value!.trim()),
                      const SizedBox(height: 20),
                      _PasswordInput(onSaved: (value) => _password = value!),
                      const SizedBox(height: 20),
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
        if (value?.isEmpty ?? true) return 'Campo obligatorio';
        if (!value!.contains('@')) return 'Correo inválido';
        return null;
      },
      onSaved: onSaved,
    );
  }
}

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
      obscureText: true,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Campo obligatorio';
        if (value!.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _RegisterViewState.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Registrarse',
                  style: TextStyle(color: Colors.white),
                ),
      ),
    );
  }
}
