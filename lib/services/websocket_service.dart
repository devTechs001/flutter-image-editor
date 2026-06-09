import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  String? _lastMessage;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionState => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.wsUrl));
      _isConnected = true;
      _connectionController.add(true);
      _startHeartbeat();
      debugPrint('WebSocket connected');

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _lastMessage = data;
            _messageController.add(message);
          } catch (e) {
            debugPrint('WebSocket message parse error: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
          debugPrint('WebSocket disconnected');
          _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          _connectionController.add(false);
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(AppConstants.wsReconnectDelay, () {
      if (!_isConnected) {
        debugPrint('Attempting WebSocket reconnection...');
        connect();
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void sendProcessingRequest({
    required String action,
    String? imagePath,
    Map<String, dynamic>? parameters,
  }) {
    send({
      'type': 'process',
      'action': action,
      'image_path': imagePath,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void subscribeToProgress(String taskId) {
    send({
      'type': 'subscribe',
      'task_id': taskId,
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
