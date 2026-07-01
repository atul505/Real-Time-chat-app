package chat_backend.chat_backend.dto; // 1. Added the missing package

import lombok.*;
import java.time.LocalDateTime;

@Data // 2. Added Lombok to automatically create Getters, Setters, and ToString
@NoArgsConstructor // 3. Added for JSON deserialization
@AllArgsConstructor // 4. This makes your 3-argument constructor work
public class UserDTO {
    private String username;
    private String lastMessage;
    private String lastMessageSender;
    private String lastTime;
    private boolean online;
    private LocalDateTime lastSeen;
    private String profileImage;
}