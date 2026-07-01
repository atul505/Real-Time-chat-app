package chat_backend.chat_backend.repository;

import chat_backend.chat_backend.entity.Contact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ContactRepository extends JpaRepository<Contact, Long> {
    List<Contact> findByOwnerUsername(String ownerUsername);
    boolean existsByOwnerUsernameAndContactUsername(String ownerUsername, String contactUsername);
    void deleteByOwnerUsernameAndContactUsername(String ownerUsername, String contactUsername);
}
