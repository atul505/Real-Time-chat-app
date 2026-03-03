package chat_backend.chat_backend.controller;

import chat_backend.chat_backend.entity.User;
import chat_backend.chat_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController // Marks this class as a REST controller
@RequestMapping("/api/users") // Base URL for all endpoints in this class
public class UserController {

    @Autowired // Injects your UserRepository
    private UserRepository userRepository;

    // A simple GET endpoint to test database connectivity
    @GetMapping("/test")
    public String testDatabase() {
        User testUser = User.builder()
                .username("test_user_" + System.currentTimeMillis())
                .email("test" + System.currentTimeMillis() + "@example.com")
                .password("securePassword123")
                .build();

        userRepository.save(testUser); // Saves the user to Neon
        return "User saved successfully to Neon! Check your dashboard.";
    }

    // Endpoint to fetch all users
    @GetMapping
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }
}