package chat_backend.chat_backend.config;

import chat_backend.chat_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class WebSocketEventListener {

    private static final Set<String> onlineUsers = ConcurrentHashMap.newKeySet();
    // Map session ID to username for disconnect handling
    private static final Map<String, String> sessionUserMap = new ConcurrentHashMap<>();

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @EventListener
    public void handleSessionConnect(SessionConnectEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
        // Username can be passed as a STOMP header from the client
        String username = accessor.getFirstNativeHeader("username");
        String sessionId = accessor.getSessionId();
        
        if (username != null && sessionId != null) {
            onlineUsers.add(username);
            sessionUserMap.put(sessionId, username);
            
            // Update lastSeen in DB
            userRepository.findByUsername(username).ifPresent(user -> {
                user.setLastSeen(LocalDateTime.now());
                userRepository.save(user);
            });
            
            // Broadcast presence update
            broadcastPresence(username, true);
        }
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = accessor.getSessionId();
        String username = sessionUserMap.remove(sessionId);
        
        if (username != null) {
            onlineUsers.remove(username);
            
            // Update lastSeen in DB
            userRepository.findByUsername(username).ifPresent(user -> {
                user.setLastSeen(LocalDateTime.now());
                userRepository.save(user);
            });
            
            // Broadcast presence update
            broadcastPresence(username, false);
        }
    }

    private void broadcastPresence(String username, boolean online) {
        Map<String, Object> presence = Map.of(
                "username", username,
                "online", online,
                "lastSeen", LocalDateTime.now().toString()
        );
        messagingTemplate.convertAndSend("/topic/presence", (Object) presence);
    }

    public static boolean isUserOnline(String username) {
        return onlineUsers.contains(username);
    }
}
