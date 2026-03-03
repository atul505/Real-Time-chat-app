package chat_backend.chat_backend.controller;

import chat_backend.chat_backend.entity.ChatMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.LocalDateTime;
import java.util.List;

import chat_backend.chat_backend.repository.ChatMessageRepository;

@Controller
public class ChatController {

    @Autowired
    private ChatMessageRepository chatMessageRepository; // Ensure you have this repo

    @MessageMapping("/chat")
    @SendTo("/topic/messages")
    public ChatMessage sendMessage(ChatMessage message) {
        message.setTimestamp(LocalDateTime.now());
        // This line saves the message to your Neon database!
        return chatMessageRepository.save(message);
    }
    @GetMapping("/api/messages")
    @ResponseBody
    public List<ChatMessage> getChatHistory() {
        // Fetches everything you see in your Neon console!
        return chatMessageRepository.findAll();
    }
}