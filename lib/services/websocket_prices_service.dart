import 'dart:async';
import 'dart:convert'; 
import 'package:flutter/foundation.dart' show debugPrint; 
import 'package:web_socket_channel/io.dart';

class WebSocketPricesService {
  IOWebSocketChannel?
  _channel; // Canal WebSocket para conectarse al servidor de Binance.
  bool _isConnected = false; // Indica si ya está conectado o no.
  final StreamController<Map<String, double>> _pricesController =
      StreamController.broadcast();
  // Controlador de stream para emitir precios actualizados. Se usa broadcast para múltiples escuchas.

  Stream<Map<String, double>> get pricesStream => _pricesController.stream;
  // Getter para exponer el stream a otras clases.

  void connect() {
    if (_isConnected || _channel != null) return;
    // Si ya está conectado o el canal no es nulo, no vuelve a conectarse.

    _channel = IOWebSocketChannel.connect(
      'wss://stream.binance.com:9443/ws/!ticker@arr',
    ); // Conexión al WebSocket público de Binance que transmite datos de todos los pares.

    _isConnected = true; // Marca como conectado.
    debugPrint('WebSocket conectado'); // Imprime que se ha conectado.

    _channel!.stream.listen(
      (message) {
        debugPrint(
          'Datos recibidos del WebSocket: $message',
        ); // Muestra los datos crudos recibidos.

        final List<dynamic> tickers = json.decode(message);
        // Decodifica el mensaje JSON en una lista dinámica.

        final Map<String, double> parsedData = {};
        // Crea un mapa para almacenar los precios parseados.

        for (var ticker in tickers) {
          final String symbol = ticker['s'].toString().toLowerCase();
          // Obtiene el símbolo del par en minúsculas.
          final double price = double.tryParse(ticker['c'].toString()) ?? 0;
          // Intenta convertir el precio a double; si falla, asigna 0.
          parsedData[symbol] = price; // Añade el símbolo y el precio al mapa.
        }

        debugPrint(
          'Datos parseados: $parsedData',
        ); // Imprime los datos ya parseados.

        if (!_pricesController.isClosed) {
          _pricesController.add(parsedData);
          // Emite los datos parseados a través del stream si no está cerrado.
        }
      },
      onError: (error) {
        debugPrint('WebSocket error: $error'); // Muestra el error si ocurre.
        disconnect(); // Desconecta si hay un error.
      },
      onDone: () {
        debugPrint(
          'WebSocket cerrado por el servidor',
        ); // Imprime cuando el servidor cierra la conexión.
        disconnect(); // Desconecta cuando se termina el stream.
      },
      cancelOnError: true, // Cancela automáticamente si hay un error.
    );
  }

  void disconnect() {
    if (_isConnected) {
      _channel?.sink.close(); // Cierra el canal si está conectado.
      _channel = null; // Elimina la referencia al canal.
      _isConnected = false; // Marca como desconectado.
      debugPrint('WebSocket desconectado'); // Informa que se ha desconectado.
    }
  }

  void dispose() {
    disconnect(); // Desconecta el canal.
    _pricesController.close(); // Cierra el controlador del stream.
    debugPrint(
      'WebSocketPricesService disposed',
    ); // Imprime que el servicio ha sido eliminado.
  }
}
