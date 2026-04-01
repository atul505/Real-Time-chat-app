package chat_backend.chat_backend.controller;

import chat_backend.chat_backend.entity.ChatMessage;
import chat_backend.chat_backend.repository.ChatMessageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class ChatController {

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate; // Required for private routing

    /**
     * Handles incoming real-time messages.
     * Saves to Neon and sends ONLY to the intended receiver.
     */
    @MessageMapping("/chat")
    public void processMessage(@Payload ChatMessage chatMessage) {
        // 1. Save to Neon (This now includes the sender and receiver names)
        ChatMessage savedMsg = chatMessageRepository.save(chatMessage);

        // 2. Send to the specific receiver's private queue
        messagingTemplate.convertAndSendToUser(
                chatMessage.getReceiver(), "/queue/messages", savedMsg
        );

        // 3. Optional: Send back to sender so their UI updates immediately
        messagingTemplate.convertAndSendToUser(
                chatMessage.getSender(), "/queue/messages", savedMsg
        );
    }

    /**
     * Fetches private history between two users.
     * Use this in Flutter: /api/messages?user1=Atul505&user2=Atulk
     */
    @GetMapping("/api/messages")
    public List<ChatMessage> getChatHistory(
            @RequestParam String user1,
            @RequestParam String user2) {
        // Uses the custom query we added to your repository
        return chatMessageRepository.findBySenderAndReceiverOrSenderAndReceiverOrderByTimestampAsc(
                user1, user2, user2, user1
        );
    }
}