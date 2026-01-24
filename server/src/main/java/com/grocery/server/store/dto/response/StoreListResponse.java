package com.grocery.server.store.dto.response;

import com.grocery.server.store.entity.Store;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: StoreListResponse
 * Mục đích: Response đơn giản để hiển thị danh sách stores
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreListResponse {

    private Long id;
    private String storeName;
    private String address;
    private String phoneNumber;
    private String imageUrl;
    private Boolean isOpen;

    /**
     * Convert từ Entity sang DTO
     */
    public static StoreListResponse fromEntity(Store store) {
        return StoreListResponse.builder()
                .id(store.getId())
                .storeName(store.getStoreName())
                .address(store.getAddress())
                .phoneNumber(store.getPhoneNumber())
                .imageUrl(store.getImageUrl())
                .isOpen(store.getIsOpen())
                .build();
    }
}
