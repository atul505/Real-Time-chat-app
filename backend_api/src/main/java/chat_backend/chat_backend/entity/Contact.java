package chat_backend.chat_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "contacts", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"owner_username", "contact_username"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Contact {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "owner_username", nullable = false)
    private String ownerUsername;

    @Column(name = "contact_username", nullable = false)
    private String contactUsername;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
