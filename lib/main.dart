import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_crypto_binance/firebase_options.dart';
import 'screens/home_screen.dart';
import 'blocs/crypto_bloc.dart';
import 'services/crypto_detail_service.dart'; // Cambiado a CryptoDetailService
import 'services/websocket_prices_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CryptoBloc(
        cryptoService: CryptoDetailService(),
        pricesService: WebSocketPricesService(),
      ),
      child: MaterialApp(
        title: 'CoinCap API 2.0 Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: HomeScreen(),
      ),
    );
  }
}