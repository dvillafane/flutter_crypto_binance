import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/forgot_password/forgot_password_bloc.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  static const backgroundColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF424242);
  static const textColor = Colors.white;
  static const hintColor = Colors.grey;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Diseño responsivo: limitamos el ancho del contenido si la pantalla es ancha.
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

    return BlocProvider(
      create: (_) => ForgotPasswordBloc(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
          listener: (context, state) async {
            if (state is ForgotPasswordSuccess) {
              // Muestra mensaje de éxito y navega a LoginScreen después de 2 segundos
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              messenger.showSnackBar(SnackBar(content: Text(state.message)));

              await Future.delayed(const Duration(seconds: 2));

              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            } else if (state is ForgotPasswordFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Recupera tu cuenta",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Ingresa tu dirección de correo electrónico para recibir instrucciones.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: hintColor),
                          ),
                          const SizedBox(height: 30),
                          Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  TextFormField(
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
                                  const SizedBox(height: 30),
                                  BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                                    builder: (context, state) {
                                      final isLoading = state is ForgotPasswordLoading;
                                      return AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: SizedBox(
                                          key: ValueKey(isLoading),
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: isLoading
                                                ? null
                                                : () {
                                                    final email = emailController.text.trim();
                                                    if (email.isNotEmpty && email.contains('@')) {
                                                      context.read<ForgotPasswordBloc>().add(
                                                            ForgotPasswordSubmitted(email: email),
                                                          );
                                                    } else {
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
                                                    "Enviar instrucciones",
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
