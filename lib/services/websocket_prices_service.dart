// Importa la biblioteca para decodificar JSON.
import 'dart:convert';
// Importa el canal de WebSocket para manejar la conexión.
import 'package:web_socket_channel/io.dart';
// Importa debugPrint para imprimir mensajes en la consola de depuración.
import 'package:flutter/foundation.dart' show debugPrint;

// Servicio para manejar la conexión WebSocket y recibir precios en tiempo real.
class WebSocketPricesService {
  // Canal de conexión WebSocket.
  IOWebSocketChannel? _channel;
  // Variable que indica si el WebSocket está conectado.
  bool _isConnected = false;

  // Stream que emite un mapa con los precios actualizados de las criptomonedas.
  Stream<Map<String, double>> get pricesStream {
    // Verifica si el canal está nulo o si no está conectado.
    if (_channel == null || !_isConnected) {
      throw Exception('WebSocket no está conectado');
    }
    // Mapea los mensajes recibidos desde el canal WebSocket.
    return _channel!.stream.map((message) {
      debugPrint('Datos recibidos del WebSocket: $message');
      // Decodifica el mensaje JSON recibido desde el WebSocket.
      final List<dynamic> tickers = json.decode(message);
      final Map<String, double> parsedData = {};

      // Recorre la lista de "tickers" recibidos.
      for (var ticker in tickers) {
        // Obtiene el símbolo en minúsculas (por ejemplo, "btcusdt").
        final String symbol = ticker['s'].toString().toLowerCase();
        // Intenta convertir el precio a un valor de tipo double, si no puede, usa 0.
        final double price = double.tryParse(ticker['c'].toString()) ?? 0;
        // Asigna el precio al símbolo en el mapa.
        parsedData[symbol] = price;
      }
      debugPrint('Datos parseados: $parsedData');
      // Retorna el mapa con los precios actualizados.
      return parsedData;
    });
  }

  // Método para conectar el WebSocket.
  void connect() {
    // Verifica que no haya una conexión activa.
    if (!_isConnected) {
      // Crea el canal de conexión al WebSocket de Binance para recibir actualizaciones.
      _channel = IOWebSocketChannel.connect(
        'wss://stream.binance.com:9443/ws/!ticker@arr',
      );
      // Marca el estado como conectado.
      _isConnected = true;
      debugPrint('WebSocket conectado');
    }
  }

  // Método para desconectar el WebSocket.
  void disconnect() {
    // Verifica si el WebSocket está conectado.
    if (_isConnected) {
      // Cierra el canal de WebSocket y limpia los recursos.
      _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      debugPrint('WebSocket desconectado');
    }
  }

  // Método para liberar recursos y desconectar el WebSocket.
  void dispose() {
    disconnect();
  }
}
