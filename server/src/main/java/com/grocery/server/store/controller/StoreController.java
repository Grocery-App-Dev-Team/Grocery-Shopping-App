package com.grocery.server.store.controller;

import com.grocery.server.shared.dto.ApiResponse;
<<<<<<< Updated upstream
import com.grocery.server.store.dto.request.CreateStoreRequest;
=======
>>>>>>> Stashed changes
import com.grocery.server.store.dto.request.UpdateStoreRequest;
import com.grocery.server.store.dto.response.StoreListResponse;
import com.grocery.server.store.dto.response.StoreResponse;
import com.grocery.server.store.service.StoreService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
<<<<<<< Updated upstream
import org.springframework.http.HttpStatus;
=======
>>>>>>> Stashed changes
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller: StoreController
 * Mục đích: REST API cho Store module
 * 
 * Base URL: /api/stores
 */
@RestController
@RequestMapping("/stores")
@RequiredArgsConstructor
@Slf4j
public class StoreController {

    private final StoreService storeService;

    // ========== STORE OWNER - STORE MANAGEMENT ==========
<<<<<<< Updated upstream
    
    /**
     * NOTE: Endpoint tạo Store đã được chuyển sang POST /api/auth/register
     * 
     * Khi đăng ký với role = STORE, hệ thống sẽ tự động tạo Store.
     * User không cần gọi API riêng để tạo Store nữa.
     */
=======
>>>>>>> Stashed changes

    /**
     * GET /api/stores/my-store
     * Lấy thông tin cửa hàng của mình
<<<<<<< Updated upstream
     *
     * Authorization: Bearer token (STORE role)
=======
>>>>>>> Stashed changes
     */
    @GetMapping("/my-store")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> getMyStore() {
        log.info("GET /api/stores/my-store - Get my store");
        
        StoreResponse response = storeService.getMyStore();
        
        return ResponseEntity.ok(
<<<<<<< Updated upstream
                ApiResponse.success("Lấy thông tin cửa hàng thành công", response)
        );
    }

    /**
     * PUT /api/stores/{storeId}
     * Cập nhật thông tin cửa hàng
     * 
     * Authorization: Bearer token (STORE owner)
     */
    @PutMapping("/{storeId}")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> updateStore(
            @PathVariable Long storeId,
            @Valid @RequestBody UpdateStoreRequest request) {
        
        log.info("PUT /api/stores/{} - Update store", storeId);
        
        StoreResponse response = storeService.updateStore(storeId, request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật cửa hàng thành công", response)
        );
    }

    /**
     * PATCH /api/stores/{storeId}/toggle-status
     * Mở/Đóng cửa hàng
     * 
     * Authorization: Bearer token (STORE owner)
     */
    @PatchMapping("/{storeId}/toggle-status")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> toggleStoreStatus(
            @PathVariable Long storeId) {
        
        log.info("PATCH /api/stores/{}/toggle-status", storeId);
        
        StoreResponse response = storeService.toggleStoreStatus(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật trạng thái cửa hàng thành công", response)
        );
    }

    /**
     * DELETE /api/stores/{storeId}
     * Xóa cửa hàng
     * 
     * Authorization: Bearer token (STORE owner or ADMIN)
     */
    @DeleteMapping("/{storeId}")
    @PreAuthorize("hasRole('STORE') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteStore(
            @PathVariable Long storeId) {
        
        log.info("DELETE /api/stores/{}", storeId);
        
        storeService.deleteStore(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa cửa hàng thành công", null)
        );
    }

    // ========== PUBLIC - VIEW STORES ==========
=======
                ApiResponse.success("Lấy thông tin cửa hàng thành công", response));
    }

    /**
     * PUT /api/stores/{id}
     * Cập nhật thông tin cửa hàng
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> updateStore(
            @PathVariable Long id,
            @Valid @RequestBody UpdateStoreRequest request) {
        
        log.info("PUT /api/stores/{} - Update store", id);
        
        StoreResponse response = storeService.updateStore(id, request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật cửa hàng thành công", response));
    }

    /**
     * PATCH /api/stores/{id}/toggle-status
     * Mở/đóng cửa hàng
     */
    @PatchMapping("/{id}/toggle-status")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> toggleStoreStatus(
            @PathVariable Long id) {
        
        log.info("PATCH /api/stores/{}/toggle-status", id);
        
        StoreResponse response = storeService.toggleStoreStatus(id);
        
        String message = response.getIsOpen() ? 
                "Đã mở cửa hàng" : "Đã đóng cửa hàng";
        
        return ResponseEntity.ok(ApiResponse.success(message, response));
    }

    /**
     * DELETE /api/stores/{id}
     * Xóa cửa hàng
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('STORE') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteStore(@PathVariable Long id) {
        log.info("DELETE /api/stores/{}", id);
        
        storeService.deleteStore(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa cửa hàng thành công", null));
    }

    // ========== PUBLIC ENDPOINTS - NO AUTH REQUIRED ==========
>>>>>>> Stashed changes

    /**
     * GET /api/stores
     * Lấy danh sách tất cả cửa hàng
<<<<<<< Updated upstream
     * 
     * Public endpoint (không cần authentication)
=======
>>>>>>> Stashed changes
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<StoreListResponse>>> getAllStores() {
        log.info("GET /api/stores - Get all stores");
        
<<<<<<< Updated upstream
        List<StoreListResponse> stores = storeService.getAllStores();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách cửa hàng thành công", stores)
        );
    }

    /**
     * GET /api/stores/{storeId}
     * Lấy thông tin chi tiết cửa hàng
     * 
     * Public endpoint
     */
    @GetMapping("/{storeId}")
    public ResponseEntity<ApiResponse<StoreResponse>> getStoreById(
            @PathVariable Long storeId) {
        
        log.info("GET /api/stores/{} - Get store detail", storeId);
        
        StoreResponse response = storeService.getStoreById(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin cửa hàng thành công", response)
        );
    }

=======
        List<StoreListResponse> response = storeService.getAllStores();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách cửa hàng thành công", response));
    }

    /**
     * GET /api/stores/{id}
     * Lấy thông tin chi tiết 1 cửa hàng
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<StoreResponse>> getStoreById(@PathVariable Long id) {
        log.info("GET /api/stores/{} - Get store detail", id);
        
        StoreResponse response = storeService.getStoreById(id);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin cửa hàng thành công", response));
    }

    /**
         * GET /api/stores/open
     * Lấy danh sách cửa hàng đang mở cửa
     */
>>>>>>> Stashed changes
    @GetMapping("/open")
    public ResponseEntity<ApiResponse<List<StoreListResponse>>> getOpenStores() {
        log.info("GET /api/stores/open - Get open stores");
        
<<<<<<< Updated upstream
        List<StoreListResponse> stores = storeService.getOpenStores();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách cửa hàng đang mở thành công", stores)
        );
    }

=======
        List<StoreListResponse> response = storeService.getOpenStores();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách cửa hàng đang mở thành công", response));
    }

    /**
     * GET /api/stores/search?keyword=...
     * Tìm kiếm cửa hàng theo tên hoặc địa chỉ
     */
>>>>>>> Stashed changes
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<StoreListResponse>>> searchStores(
            @RequestParam String keyword) {
        
        log.info("GET /api/stores/search?keyword={}", keyword);
        
<<<<<<< Updated upstream
        List<StoreListResponse> stores = storeService.searchStores(keyword);
        
        return ResponseEntity.ok(
                ApiResponse.success("Tìm kiếm cửa hàng thành công", stores)
        );
=======
        List<StoreListResponse> response = storeService.searchStores(keyword);
        
        return ResponseEntity.ok(
                ApiResponse.success("Tìm kiếm cửa hàng thành công", response));
>>>>>>> Stashed changes
    }
}
