import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Tickers',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TickerScreen(),
    );
  }
}

class TickerScreen extends StatefulWidget {
  const TickerScreen({super.key});
  @override
  State<TickerScreen> createState() => _TickerScreenState();
}

class _TickerScreenState extends State<TickerScreen> {
  late final WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    // Conectamos al websocket que envía todos los tickers
    channel = IOWebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/!ticker@arr'),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticker de Criptomonedas'),
      ),
      body: StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Decodificamos el mensaje JSON recibido (que es un arreglo)
          final List<dynamic> tickers = jsonDecode(snapshot.data);
          // Ordenamos por símbolo para facilitar la lectura (opcional)
          tickers.sort((a, b) => (a['s'] as String).compareTo(b['s'] as String));

          return ListView.builder(
            itemCount: tickers.length,
            itemBuilder: (context, index) {
              final ticker = tickers[index];
              final String symbol = ticker['s'] ?? 'N/A';
              final String price = ticker['c'] ?? 'N/A'; // "c" es el precio actual
              return ListTile(
                title: Text(symbol),
                subtitle: Text('Precio: \$ $price'),
              );
            },
          );
        },
      ),
    );
  }
}
