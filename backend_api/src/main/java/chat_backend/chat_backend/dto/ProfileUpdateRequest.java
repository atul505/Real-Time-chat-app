package chat_backend.chat_backend.dto;

import lombok.Data;

@Data
public class ProfileUpdateRequest {
    private String username;
    private String about;
    private String status;
}
