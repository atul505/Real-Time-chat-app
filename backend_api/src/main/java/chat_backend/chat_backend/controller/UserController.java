package chat_backend.chat_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

import chat_backend.chat_backend.dto.AuthResponse;
import chat_backend.chat_backend.dto.LoginRequest;
import chat_backend.chat_backend.dto.RegisterRequest;
import chat_backend.chat_backend.dto.UserDTO; // Ensure you created this DTO
import chat_backend.chat_backend.entity.User;
import chat_backend.chat_backend.entity.ChatMessage;
import chat_backend.chat_backend.repository.UserRepository;
import chat_backend.chat_backend.repository.ChatMessageRepository; // New Import
import chat_backend.chat_backend.service.UserService;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository; // Inject to fetch last messages

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            User registeredUser = userService.registerUser(request);
            return ResponseEntity.ok("User registered successfully with ID: " + registeredUser.getId());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            AuthResponse response = userService.loginUser(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }
    }

    /**
     * Updated to return UserDTO which includes last message preview.
     * Pass 'currentUser' from Flutter to filter out the logged-in user and find relevant chats.
     */
    @GetMapping
    public List<UserDTO> getAllUsers(@RequestParam(required = false) String currentUser) {
        List<User> users = userRepository.findAll();

        return users.stream()
                .filter(user -> currentUser == null || !user.getUsername().equals(currentUser))
                .map(user -> {
                    // Fetch the latest message between currentUser and this user
                    ChatMessage lastMsg = (currentUser != null)
                            ? chatMessageRepository.findLastMessageBetween(currentUser, user.getUsername())
                            : null;

                    String content = (lastMsg != null) ? lastMsg.getContent() : "No messages yet";
                    String time = (lastMsg != null) ? lastMsg.getTimestamp().toString() : "";

                    return new UserDTO(user.getUsername(), content, time);
                })
                .collect(Collectors.toList());
    }
}