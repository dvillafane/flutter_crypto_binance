// Importa la librería para trabajar con JSON
import 'dart:convert';
// Importa la clase IOWebSocketChannel para establecer conexiones WebSocket
import 'package:web_socket_channel/io.dart';

/// Servicio que maneja la conexión y el procesamiento de precios en tiempo real usando WebSocket.
class WebSocketPricesService {
  // Declaración de la variable de canal WebSocket
  late IOWebSocketChannel _channel;

  /// Constructor que inicia la conexión al crear una instancia del servicio.
  WebSocketPricesService() {
    _connect();
  }

  /// Método privado para conectar con el WebSocket de Binance.
  void _connect() {
    _channel = IOWebSocketChannel.connect(
      'wss://stream.binance.com:9443/ws/!ticker@arr', // Conexión al stream de tickers de Binance
    );
  }

  /// Stream que emite un mapa de precios actualizado en tiempo real.
  /// Cada mensaje del WebSocket se procesa para extraer un mapa de símbolos a precios.
  Stream<Map<String, double>> get pricesStream async* {
    // Escuchar los mensajes entrantes del WebSocket
    await for (var message in _channel.stream) {
      // Binance envía un arreglo de tickers en formato JSON
      final List<dynamic> tickers = json.decode(message);
      // Inicializamos un mapa para almacenar el símbolo y su precio correspondiente
      final Map<String, double> parsedData = {};

      // Iteramos sobre cada ticker del arreglo
      for (var ticker in tickers) {
        // Extraemos el símbolo, lo convertimos a minúsculas (ejemplo: "btcusdt")
        final String symbol = ticker['s'].toString().toLowerCase();
        // Extraemos el precio, el campo "c" representa el precio actual y se convierte a double
        final double price = double.tryParse(ticker['c'].toString()) ?? 0;
        // Se asigna el precio al símbolo en el mapa
        parsedData[symbol] = price;
      }
      // Emitir el mapa de precios procesado a través del stream
      yield parsedData;
    }
  }

  /// Método para reconectar el WebSocket.
  /// Cierra la conexión actual y establece una nueva conexión.
  void reconnect() {
    _channel.sink.close();
    _connect();
  }

  /// Método para cerrar la conexión del WebSocket de forma segura.
  void dispose() {
    _channel.sink.close();
  }
}
