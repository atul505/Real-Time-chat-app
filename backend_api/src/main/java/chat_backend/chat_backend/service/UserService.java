package chat_backend.chat_backend.service;

import chat_backend.chat_backend.config.JwtUtils;
import chat_backend.chat_backend.dto.AuthResponse;
import chat_backend.chat_backend.dto.LoginRequest;
import chat_backend.chat_backend.dto.RegisterRequest;
import chat_backend.chat_backend.entity.User;
import chat_backend.chat_backend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils; // Add this line

    // Update your constructor to include jwtUtils
    public UserService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtils jwtUtils) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtils = jwtUtils;
    }

    public AuthResponse loginUser(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }

        // Now jwtUtils will be resolved
        String token = jwtUtils.generateToken(user.getEmail());
        return new AuthResponse(token, user.getUsername());
    }
    public User registerUser(RegisterRequest request) {
        // 1. Check if the email is already taken
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("Email already in use");
        }

        // 2. Build the new User entity
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                // 3. Encrypt the password before saving
                .password(passwordEncoder.encode(request.getPassword()))
                .build();

        // 4. Save to Neon database
        return userRepository.save(user);
    }
}