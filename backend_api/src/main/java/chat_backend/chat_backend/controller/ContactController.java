package chat_backend.chat_backend.controller;

import chat_backend.chat_backend.entity.Contact;
import chat_backend.chat_backend.repository.ContactRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {

    @Autowired
    private ContactRepository contactRepository;

    @PostMapping("/add")
    public ResponseEntity<?> addContact(@RequestBody Map<String, String> request) {
        String owner = request.get("ownerUsername");
        String contact = request.get("contactUsername");

        if (owner == null || contact == null) {
            return ResponseEntity.badRequest().body("ownerUsername and contactUsername are required");
        }
        if (owner.equals(contact)) {
            return ResponseEntity.badRequest().body("Cannot add yourself as a contact");
        }
        if (contactRepository.existsByOwnerUsernameAndContactUsername(owner, contact)) {
            return ResponseEntity.badRequest().body("Contact already exists");
        }

        Contact newContact = Contact.builder()
                .ownerUsername(owner)
                .contactUsername(contact)
                .build();
        contactRepository.save(newContact);
        return ResponseEntity.ok("Contact added");
    }

    @GetMapping
    public List<Contact> getContacts(@RequestParam String username) {
        return contactRepository.findByOwnerUsername(username);
    }

    @DeleteMapping
    @Transactional
    public ResponseEntity<?> removeContact(@RequestParam String owner, @RequestParam String contact) {
        contactRepository.deleteByOwnerUsernameAndContactUsername(owner, contact);
        return ResponseEntity.ok("Contact removed");
    }
}
