import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

/// Singleton ChatService — one persistent WebSocket connection for the entire app.
/// Both the home page and chat rooms listen to the same message stream.
class ChatService {
  static ChatService? _instance;
  static String? _connectedUsername;

  StompClient? _stompClient;
  bool _isConnected = false;

  // Broadcast stream for incoming messages — multiple listeners allowed
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  ChatService._internal();

  /// Get or create the singleton instance.
  /// If the username changed (different user logged in), reconnect.
  static ChatService getInstance({String? username}) {
    if (_instance == null) {
      _instance = ChatService._internal();
      if (username != null) {
        _instance!._connect(username);
      }
    } else if (username != null && _connectedUsername != username) {
      // Different user — reconnect
      _instance!.disconnect();
      _instance = ChatService._internal();
      _instance!._connect(username);
    }
    return _instance!;
  }

  /// Connect to the STOMP WebSocket server
  void _connect(String username) {
    _connectedUsername = username;
    _stompClient = StompClient(
      config: StompConfig(
        url: ApiConfig.wsUrl,
        stompConnectHeaders: {'username': username},
        onConnect: (frame) => _onConnect(frame, username),
        onStompError: (frame) => debugPrint('Stomp Error: ${frame.body}'),
        onWebSocketError: (error) {
          debugPrint('WebSocket Error: $error');
          _isConnected = false;
          // Auto-reconnect after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (!_isConnected && _connectedUsername != null) {
              _connect(_connectedUsername!);
            }
          });
        },
        onDisconnect: (frame) {
          _isConnected = false;
        },
        // Heartbeat to keep connection alive
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        // Auto reconnect
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame, String username) {
    _isConnected = true;
    _stompClient!.subscribe(
      destination: '/user/$username/queue/messages',
      callback: (frame) {
        if (frame.body != null) {
          final message = jsonDecode(frame.body!);
          _messageController.add(message);
        }
      },
    );
  }

  /// Send a chat message
  void sendMessage(String sender, String content, String receiver,
      {String? attachmentUrl, String? attachmentType, String? attachmentName}) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('Warning: STOMP not connected, attempting reconnect...');
      if (_connectedUsername != null) _connect(_connectedUsername!);
      return;
    }
    final message = {
      'sender': sender,
      'content': content,
      'receiver': receiver,
      'timestamp': DateTime.now().toIso8601String(),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentType != null) 'attachmentType': attachmentType,
      if (attachmentName != null) 'attachmentName': attachmentName,
    };
    _stompClient!.send(
      destination: '/app/chat',
      body: jsonEncode(message),
    );
  }

  /// Disconnect and clean up — call on logout only
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
    _connectedUsername = null;
  }

  /// Full teardown — call on logout
  static void destroy() {
    _instance?.disconnect();
    _instance?._messageController.close();
    _instance = null;
  }
}