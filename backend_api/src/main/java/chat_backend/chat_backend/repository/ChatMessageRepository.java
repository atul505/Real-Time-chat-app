package chat_backend.chat_backend.repository;

import chat_backend.chat_backend.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    /**
     * Fetches the full private chat history between two users.
     * Matches (Me -> You) OR (You -> Me) and sorts by time.
     */
    List<ChatMessage> findBySenderAndReceiverOrSenderAndReceiverOrderByTimestampAsc(
            String sender1, String receiver1, String sender2, String receiver2
    );

    /**
     * Native query to find only the single most recent message for the HomePage preview.
     * This targets your new 'chat_messages' table in Neon.
     */
    @Query(value = "SELECT * FROM chat_messages WHERE (sender = ?1 AND receiver = ?2) " +
            "OR (sender = ?2 AND receiver = ?1) " +
            "ORDER BY timestamp DESC LIMIT 1", nativeQuery = true)
    ChatMessage findLastMessageBetween(String user1, String user2);
}