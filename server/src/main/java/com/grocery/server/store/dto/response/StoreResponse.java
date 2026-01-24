package com.grocery.server.store.dto.response;

import com.grocery.server.store.entity.Store;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO: StoreResponse
 * Mục đích: Response chứa thông tin cửa hàng
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreResponse {

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
     */
    public static StoreResponse fromEntity(Store store) {
        return StoreResponse.builder()
                .id(store.getId())
                .ownerId(store.getOwner().getId())
                .ownerName(store.getOwner().getFullName())
                .storeName(store.getStoreName())
                .address(store.getAddress())
                .phoneNumber(store.getPhoneNumber())
                .description(store.getDescription())
                .imageUrl(store.getImageUrl())
                .isOpen(store.getIsOpen())
                .createdAt(store.getCreatedAt())
                .updatedAt(store.getUpdatedAt())
                .build();
    }
}
