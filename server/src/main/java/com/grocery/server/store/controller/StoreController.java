package com.grocery.server.store.controller;

import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.store.dto.request.CreateStoreRequest;
import com.grocery.server.store.dto.request.UpdateStoreRequest;
import com.grocery.server.store.dto.response.StoreListResponse;
import com.grocery.server.store.dto.response.StoreResponse;
import com.grocery.server.store.service.StoreService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
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

    /**
     * POST /api/stores
     * Tạo cửa hàng mới
     * 
     * Authorization: Bearer token (STORE role only)
     * 
     * Request Body:
     * {
     *   "storeName": "Tạp hóa ABC",
     *   "address": "123 Đường XYZ",
     *   "phoneNumber": "0912345678",
     *   "description": "Tạp hóa bán đồ tươi sống",
     *   "imageUrl": "https://..."
     * }
     */
    @PostMapping
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> createStore(
            @Valid @RequestBody CreateStoreRequest request) {
        
        log.info("POST /api/stores - Create new store");
        
        StoreResponse response = storeService.createStore(request);
        
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo cửa hàng thành công", response));
    }

    /**
     * GET /api/stores/my-store
     * Lấy thông tin cửa hàng của mình
     * 
     * Authorization: Bearer token (STORE role)
     */
    @GetMapping("/my-store")
    @PreAuthorize("hasRole('STORE')")
    public ResponseEntity<ApiResponse<StoreResponse>> getMyStore() {
        log.info("GET /api/stores/my-store - Get my store");
        
        StoreResponse response = storeService.getMyStore();
        
        return ResponseEntity.ok(
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

    /**
     * GET /api/stores
     * Lấy danh sách tất cả cửa hàng
     * 
     * Public endpoint (không cần authentication)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<StoreListResponse>>> getAllStores() {
        log.info("GET /api/stores - Get all stores");
        
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

    @GetMapping("/open")
    public ResponseEntity<ApiResponse<List<StoreListResponse>>> getOpenStores() {
        log.info("GET /api/stores/open - Get open stores");
        
        List<StoreListResponse> stores = storeService.getOpenStores();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách cửa hàng đang mở thành công", stores)
        );
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<StoreListResponse>>> searchStores(
            @RequestParam String keyword) {
        
        log.info("GET /api/stores/search?keyword={}", keyword);
        
        List<StoreListResponse> stores = storeService.searchStores(keyword);
        
        return ResponseEntity.ok(
                ApiResponse.success("Tìm kiếm cửa hàng thành công", stores)
        );
    }
}
