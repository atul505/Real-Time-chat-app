package chat_backend.chat_backend.repository;

import chat_backend.chat_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Custom query methods that Spring Data JPA generates automatically
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
}