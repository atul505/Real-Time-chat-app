package chat_backend.chat_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;

import chat_backend.chat_backend.dto.AuthResponse;
import chat_backend.chat_backend.dto.LoginRequest;
import chat_backend.chat_backend.dto.RegisterRequest;
import chat_backend.chat_backend.dto.UserDTO;
import chat_backend.chat_backend.dto.ProfileUpdateRequest;
import chat_backend.chat_backend.entity.User;
import chat_backend.chat_backend.entity.ChatMessage;
import chat_backend.chat_backend.entity.Contact;
import chat_backend.chat_backend.repository.UserRepository;
import chat_backend.chat_backend.repository.ChatMessageRepository;
import chat_backend.chat_backend.repository.ContactRepository;
import chat_backend.chat_backend.service.UserService;
import chat_backend.chat_backend.config.WebSocketEventListener;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private ContactRepository contactRepository;

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

    @GetMapping("/{username}/profile")
    public ResponseEntity<?> getUserProfile(@PathVariable String username) {
        return userRepository.findByUsername(username)
            .map(user -> {
                Map<String, Object> profile = new HashMap<>();
                profile.put("username", user.getUsername());
                profile.put("email", user.getEmail());
                profile.put("about", user.getAbout());
                profile.put("status", user.getStatus());
                profile.put("profileImage", user.getProfileImage());
                profile.put("lastSeen", user.getLastSeen());
                return ResponseEntity.ok(profile);
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestBody ProfileUpdateRequest request) {
        return userRepository.findByUsername(request.getUsername())
            .map(user -> {
                if (request.getAbout() != null) {
                    String[] words = request.getAbout().trim().split("\\s+");
                    if (words.length > 50) {
                        return ResponseEntity.badRequest().body("About must be 50 words or less");
                    }
                    user.setAbout(request.getAbout());
                }
                if (request.getStatus() != null) {
                    String[] words = request.getStatus().trim().split("\\s+");
                    if (words.length > 50) {
                        return ResponseEntity.badRequest().body("Status must be 50 words or less");
                    }
                    user.setStatus(request.getStatus());
                }
                userRepository.save(user);
                return ResponseEntity.ok("Profile updated");
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{username}/status")
    public ResponseEntity<?> getUserStatus(@PathVariable String username) {
        return userRepository.findByUsername(username)
            .map(user -> {
                Map<String, Object> status = new HashMap<>();
                status.put("online", WebSocketEventListener.isUserOnline(username));
                status.put("lastSeen", user.getLastSeen());
                return ResponseEntity.ok(status);
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/search")
    public ResponseEntity<?> searchUsers(@RequestParam String q, @RequestParam String currentUser) {
        List<User> users = userRepository.searchUsers(q, currentUser);
        List<Contact> existingContacts = contactRepository.findByOwnerUsername(currentUser);
        Set<String> contactNames = existingContacts.stream()
                .map(Contact::getContactUsername)
                .collect(Collectors.toSet());
        
        List<Map<String, String>> results = users.stream()
                .filter(u -> !contactNames.contains(u.getUsername()))
                .map(u -> {
                    Map<String, String> map = new HashMap<>();
                    map.put("username", u.getUsername());
                    map.put("email", u.getEmail());
                    map.put("profileImage", u.getProfileImage());
                    return map;
                })
                .collect(Collectors.toList());
        return ResponseEntity.ok(results);
    }

    @GetMapping
    public List<UserDTO> getAllUsers(@RequestParam(required = false) String currentUser) {
        if (currentUser == null) {
            return userRepository.findAll().stream()
                    .map(u -> new UserDTO(u.getUsername(), "No messages yet", "", false, null, u.getProfileImage()))
                    .collect(Collectors.toList());
        }
        
        List<Contact> contacts = contactRepository.findByOwnerUsername(currentUser);
        Set<String> contactNames = contacts.stream()
                .map(Contact::getContactUsername)
                .collect(Collectors.toSet());
        
        List<User> allUsers = userRepository.findAll();
        List<UserDTO> result = new ArrayList<>();
        
        for (User user : allUsers) {
            if (user.getUsername().equals(currentUser)) continue;
            
            boolean isContact = contactNames.contains(user.getUsername());
            ChatMessage lastMsg = chatMessageRepository.findLastMessageBetween(currentUser, user.getUsername());
            boolean hasConversation = lastMsg != null;
            
            if (isContact || hasConversation) {
                String content = hasConversation ? lastMsg.getContent() : "No messages yet";
                String time = hasConversation ? lastMsg.getTimestamp().toString() : "";
                boolean online = WebSocketEventListener.isUserOnline(user.getUsername());
                result.add(new UserDTO(user.getUsername(), content, time, online, user.getLastSeen(), user.getProfileImage()));
            }
        }
        
        result.sort((a, b) -> {
            String timeA = a.getLastTime() != null ? a.getLastTime() : "";
            String timeB = b.getLastTime() != null ? b.getLastTime() : "";
            return timeB.compareTo(timeA);
        });
        
        return result;
    }
}