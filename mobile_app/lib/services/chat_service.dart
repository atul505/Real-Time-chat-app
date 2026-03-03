import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

import 'package:stomp_dart_client/stomp_frame.dart';

class ChatService {
  late StompClient stompClient;
  final Function(Map<String, dynamic>) onMessageReceived;

  ChatService({required this.onMessageReceived}) {
    stompClient = StompClient(
      config: StompConfig(
        // Use 'localhost' because of your successful ADB reverse!
        url: 'ws://localhost:8080/ws',
        onConnect: onConnect,
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onWebSocketError: (dynamic error) => print('Websocket Error: $error'),
      ),
    );
    stompClient.activate();
  }

  void onConnect(StompFrame frame) {
    // Subscribe to the topic we defined in Spring Boot's ChatController
    stompClient.subscribe(
      destination: '/topic/messages',
      callback: (frame) {
        if (frame.body != null) {
          onMessageReceived(jsonDecode(frame.body!));
        }
      },
    );
  }

  void sendMessage(String sender, String content) {
    stompClient.send(
      destination: '/app/chat', // Matches @MessageMapping("/chat")
      body: jsonEncode({
        'sender': sender,
        'content': content,
      }),
    );
  }

  void disconnect() {
    stompClient.deactivate();
  }
}