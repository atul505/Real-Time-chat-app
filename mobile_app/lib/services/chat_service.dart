import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ChatService {
  late StompClient stompClient;
  final Function(Map<String, dynamic>) onMessageReceived;
  final String? username;

  ChatService({required this.onMessageReceived, this.username}) {
    stompClient = StompClient(
      config: StompConfig(
        url: ApiConfig.wsUrl,
        onConnect: onConnect,
        stompConnectHeaders: username != null ? {'username': username!} : {},
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onWebSocketError: (dynamic error) => print('Websocket Error: $error'),
      ),
    );
    stompClient.activate();
  }

  void onConnect(StompFrame frame) async {
    final String? myName = username ?? await AuthService().getUsername();

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

  void sendMessage(String sender, String content, String receiver,
      {String? attachmentUrl, String? attachmentType, String? attachmentName}) {
    final message = {
      'sender': sender,
      'content': content,
      'receiver': receiver,
      'timestamp': DateTime.now().toIso8601String(),
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentType != null) 'attachmentType': attachmentType,
      if (attachmentName != null) 'attachmentName': attachmentName,
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