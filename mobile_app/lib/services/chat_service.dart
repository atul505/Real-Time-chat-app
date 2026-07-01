import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'auth_service.dart'; // Add this line at the top
import '../config/api_config.dart';

import 'package:stomp_dart_client/stomp_frame.dart';

class ChatService {
  late StompClient stompClient;
  final Function(Map<String, dynamic>) onMessageReceived;

  ChatService({required this.onMessageReceived}) {
    stompClient = StompClient(
      config: StompConfig(
        url: ApiConfig.wsUrl,
        onConnect: onConnect,
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onWebSocketError: (dynamic error) => print('Websocket Error: $error'),
      ),
    );
    stompClient.activate();
  }

  // Inside ChatService.dart
  void onConnect(StompFrame frame) async {
    // Use the newly defined getUsername method
    final String? myName = await AuthService().getUsername();

    if (myName != null) {
      stompClient.subscribe(
        destination: '/user/$myName/queue/messages',
        callback: (frame) {
          if (frame.body != null) {
            onMessageReceived(jsonDecode(frame.body!));
          }
        },
      );
    }
  }

  void sendMessage(String sender, String content, String receiver, {String? attachmentUrl, String? attachmentType, String? attachmentName}) {
    final message = {
      'sender': sender,
      'content': content,
      'receiver': receiver,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'attachmentName': attachmentName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    stompClient.send(
      destination: '/app/chat',
      body: jsonEncode(message),
    );
  }
  void disconnect() {
    stompClient.deactivate();
  }
}