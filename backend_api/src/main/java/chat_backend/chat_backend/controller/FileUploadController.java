package chat_backend.chat_backend.controller;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import chat_backend.chat_backend.entity.User;
import chat_backend.chat_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/upload")
public class FileUploadController {

    @Autowired
    private Cloudinary cloudinary;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/profile-image")
    public ResponseEntity<?> uploadProfileImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam("username") String username) {
        try {
            // Validate file size (5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest().body("File size must be under 5MB");
            }
            
            // Validate image type
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest().body("Only image files are allowed");
            }

            // Upload to Cloudinary
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "chat-app/profile-images",
                    "public_id", username + "_profile",
                    "overwrite", true,
                    "transformation", new com.cloudinary.Transformation().width(400).height(400).crop("fill").gravity("face")
            ));

            String imageUrl = (String) uploadResult.get("secure_url");

            // Update user's profileImage in DB
            userRepository.findByUsername(username).ifPresent(user -> {
                user.setProfileImage(imageUrl);
                userRepository.save(user);
            });

            return ResponseEntity.ok(Map.of("url", imageUrl));
        } catch (IOException e) {
            return ResponseEntity.internalServerError().body("Upload failed: " + e.getMessage());
        }
    }

    @PostMapping("/attachment")
    public ResponseEntity<?> uploadAttachment(@RequestParam("file") MultipartFile file) {
        try {
            // Validate file size (5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest().body("File size must be under 5MB");
            }

            String contentType = file.getContentType();
            boolean isImage = contentType != null && contentType.startsWith("image/");
            String resourceType = isImage ? "image" : "raw";

            // Upload to Cloudinary
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "chat-app/attachments",
                    "resource_type", resourceType
            ));

            String fileUrl = (String) uploadResult.get("secure_url");

            return ResponseEntity.ok(Map.of(
                    "url", fileUrl,
                    "type", isImage ? "image" : "file",
                    "name", file.getOriginalFilename() != null ? file.getOriginalFilename() : "attachment",
                    "size", file.getSize()
            ));
        } catch (IOException e) {
            return ResponseEntity.internalServerError().body("Upload failed: " + e.getMessage());
        }
    }
}
