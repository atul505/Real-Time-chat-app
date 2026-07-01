package chat_backend.chat_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "chat_messages") // Explicitly naming the table
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String sender;
    private String receiver;
    @Column(nullable = false, columnDefinition = "TEXT") // Supports long messages
    private String content;

    @Column(name = "timestamp")
    private LocalDateTime timestamp;

    private String attachmentUrl;
    private String attachmentType;
    private String attachmentName;

    // Automatically set the server time when a message is first created
    @PrePersist
    protected void onCreate() {
        if (this.timestamp == null) {
            this.timestamp = LocalDateTime.now();
        }
    }
}