package com.grocery.server.store.dto.response;

import com.grocery.server.store.entity.Store;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

<<<<<<< Updated upstream
import java.time.LocalDateTime;

/**
 * DTO: StoreResponse
 * Mục đích: Response chứa thông tin cửa hàng
=======
/**
 * DTO Response: StoreResponse
 * Mục đích: Trả về thông tin chi tiết cửa hàng
>>>>>>> Stashed changes
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreResponse {
<<<<<<< Updated upstream

    private Long id;
    private Long ownerId;
    private String ownerName;
    private String storeName;
    private String address;
    private String phoneNumber;
    private String description;
    private String imageUrl;
    private Boolean isOpen;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Convert từ Entity sang DTO
=======
    
    private Long id;
    private Long ownerId;
    private String ownerName;
    private String ownerPhone;
    private String storeName;
    private String address;
    private Boolean isOpen;
    
    /**
     * Chuyển từ Store entity sang StoreResponse DTO
>>>>>>> Stashed changes
     */
    public static StoreResponse fromEntity(Store store) {
        return StoreResponse.builder()
                .id(store.getId())
                .ownerId(store.getOwner().getId())
                .ownerName(store.getOwner().getFullName())
<<<<<<< Updated upstream
                .storeName(store.getStoreName())
                .address(store.getAddress())
                .phoneNumber(store.getPhoneNumber())
                .description(store.getDescription())
                .imageUrl(store.getImageUrl())
                .isOpen(store.getIsOpen())
                .createdAt(store.getCreatedAt())
                .updatedAt(store.getUpdatedAt())
=======
                .ownerPhone(store.getOwner().getPhoneNumber())
                .storeName(store.getStoreName())
                .address(store.getAddress())
                .isOpen(store.getIsOpen())
>>>>>>> Stashed changes
                .build();
    }
}
