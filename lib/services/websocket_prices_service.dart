// Importa la librería para manejar la conversión de datos en formato JSON.
import 'dart:convert';
// Importa el paquete web_socket_channel para establecer conexiones WebSocket.
import 'package:web_socket_channel/io.dart';

// Clase que se encarga de conectar y recibir actualizaciones de precios a través de WebSocket.
class WebSocketPricesService {
  late IOWebSocketChannel _channel;

  WebSocketPricesService() {
    _connect();
  }
  // Se crea y establece la conexión WebSocket con la URL especificada.
  // En este caso, se conecta a la API de CoinCap para obtener precios de todos los activos.
  void _connect() {
    _channel = IOWebSocketChannel.connect(
      'wss://ws.coincap.io/prices?assets=ALL',
    );
  }

  // Getter que retorna un Stream de mapas, donde cada mapa contiene pares clave-valor (nombre del activo y su precio).
  Stream<Map<String, double>> get pricesStream async* {
    // Se espera y procesa cada mensaje recibido por el canal WebSocket.
    await for (var message in _channel.stream) {
      // Decodifica el mensaje recibido (en formato JSON) a un mapa dinámico.
      final Map<String, dynamic> data = json.decode(message);
      // Crea un mapa vacío para almacenar los datos de precios convertidos a double.
      final Map<String, double> parsedData = {};
      // Itera sobre cada par clave-valor en el mapa decodificado.
      data.forEach((key, value) {
        // Intenta convertir el valor a double; si falla, asigna 0.
        parsedData[key] = double.tryParse(value.toString()) ?? 0;
      });
      // Emite el mapa de datos procesado a través del stream.
      yield parsedData;
    }
  }

  // Método para reconectar el WebSocket
  void reconnect() {
    _channel.sink.close();
    _connect();
  }

  // Método para cerrar la conexión WebSocket y liberar recursos.
  void dispose() {
    _channel.sink.close();
  }
}
