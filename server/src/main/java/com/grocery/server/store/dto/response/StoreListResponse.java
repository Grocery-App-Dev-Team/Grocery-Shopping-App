package com.grocery.server.store.dto.response;

import com.grocery.server.store.entity.Store;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
<<<<<<< Updated upstream
 * DTO: StoreListResponse
 * Mục đích: Response đơn giản để hiển thị danh sách stores
=======
 * DTO Response: StoreListResponse
 * Mục đích: Trả về danh sách cửa hàng (rút gọn thông tin)
>>>>>>> Stashed changes
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StoreListResponse {
<<<<<<< Updated upstream

    private Long id;
    private String storeName;
    private String address;
    private String phoneNumber;
    private String imageUrl;
    private Boolean isOpen;

    /**
     * Convert từ Entity sang DTO
=======
    
    private Long id;
    private String storeName;
    private String address;
    private Boolean isOpen;
    private String ownerName;
    
    /**
     * Chuyển từ Store entity sang StoreListResponse DTO
>>>>>>> Stashed changes
     */
    public static StoreListResponse fromEntity(Store store) {
        return StoreListResponse.builder()
                .id(store.getId())
                .storeName(store.getStoreName())
                .address(store.getAddress())
<<<<<<< Updated upstream
                .phoneNumber(store.getPhoneNumber())
                .imageUrl(store.getImageUrl())
                .isOpen(store.getIsOpen())
=======
                .isOpen(store.getIsOpen())
                .ownerName(store.getOwner().getFullName())
>>>>>>> Stashed changes
                .build();
    }
}
