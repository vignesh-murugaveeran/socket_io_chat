import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

/// Singleton Socket.IO service
/// - Auto-reconnect with backoff
/// - Proper listener cleanup
/// - Disconnect on logout
/// - Connection state management
class SocketService extends GetxService {
  static SocketService get to => Get.find<SocketService>();

  io.Socket? _socket;

  io.Socket? get socket => _socket;

  // Connection state
  final isConnected = false.obs;
  final isReconnecting = false.obs;

  /// Connect to Socket.IO server with JWT token
  void connect(String token) {
    // Prevent duplicate connections
    if (_socket != null && _socket!.connected) {
      debugPrint('⚡ Socket already connected');
      return;
    }

    debugPrint('🔌 Connecting to Socket.IO: ${AppConfig.socketUrl}');

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport only
          .setAuth({'token': token}) // JWT auth in handshake
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000) // 1 second initial delay
          .setReconnectionDelayMax(5000) // Max 5 second delay
          .build(),
    );

    // ── Connection Events ─────────────────────────────────────────────────
    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected: ${_socket!.id}');
      isConnected.value = true;
      isReconnecting.value = false;
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Socket disconnected');
      isConnected.value = false;
    });

    _socket!.on('reconnecting', (_) {
      debugPrint('🔄 Socket reconnecting...');
      isReconnecting.value = true;
    });

    _socket!.onReconnect((_) {
      debugPrint('✅ Socket reconnected');
      isConnected.value = true;
      isReconnecting.value = false;
    });

    _socket!.onConnectError((error) {
      debugPrint('⚠️ Socket connection error: $error');
      isConnected.value = false;
    });

    _socket!.onError((error) {
      debugPrint('⚠️ Socket error: $error');
    });
  }

  /// Disconnect socket — call on logout
  void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 Disconnecting socket...');
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      isConnected.value = false;
      isReconnecting.value = false;
    }
  }

  /// Emit an event to the server
  void emit(String event, [dynamic data]) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      debugPrint('⚠️ Cannot emit "$event": Socket not connected');
    }
  }

  /// Listen for an event from the server
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Remove a specific event listener
  void off(String event) {
    _socket?.off(event);
  }

  /// Remove all listeners for cleanup
  void removeAllListeners() {
    _socket?.clearListeners();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
