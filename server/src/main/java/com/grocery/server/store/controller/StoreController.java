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

    /**
     * Tạo cửa hàng mới
     * POST /api/stores
     * Yêu cầu: User đã đăng nhập
     */
    @PostMapping
    public ResponseEntity<ApiResponse<StoreResponse>> createStore(
            @Valid @RequestBody CreateStoreRequest request) {
        
        log.info("POST /api/stores - Create new store");
        
        StoreResponse store = storeService.createStore(request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo cửa hàng thành công", store));
    }

    /**
     * Lấy thông tin cửa hàng của user hiện tại
     * GET /api/stores/my-store
     * Yêu cầu: User đã đăng nhập
     */
    @GetMapping("/my-store")
    public ResponseEntity<ApiResponse<StoreResponse>> getMyStore() {
        
        log.info("GET /api/stores/my-store - Get current user's store");
        
        StoreResponse store = storeService.getMyStore();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin cửa hàng thành công", store)
        );
    }

    /**
     * Lấy tất cả cửa hàng (Public)
     * GET /api/stores
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
     * Lấy thông tin cửa hàng theo ID (Public)
     * GET /api/stores/{storeId}
     */
    @GetMapping("/{storeId}")
    public ResponseEntity<ApiResponse<StoreResponse>> getStoreById(
            @PathVariable Long storeId) {
        
        log.info("GET /api/stores/{} - Get store by ID", storeId);
        
        StoreResponse store = storeService.getStoreById(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin cửa hàng thành công", store)
        );
    }

    /**
     * Cập nhật thông tin cửa hàng
     * PUT /api/stores
     * Yêu cầu: User đã đăng nhập và là chủ cửa hàng
     */
    @PutMapping
    public ResponseEntity<ApiResponse<StoreResponse>> updateStore(
            @Valid @RequestBody UpdateStoreRequest request) {
        
        log.info("PUT /api/stores - Update store");
        
        StoreResponse store = storeService.updateStore(request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật cửa hàng thành công", store)
        );
    }

    /**
     * Toggle trạng thái mở/đóng cửa hàng
     * PATCH /api/stores/toggle-status
     * Yêu cầu: User đã đăng nhập và là chủ cửa hàng
     */
    @PatchMapping("/toggle-status")
    public ResponseEntity<ApiResponse<StoreResponse>> toggleStoreStatus() {
        
        log.info("PATCH /api/stores/toggle-status - Toggle store status");
        
        StoreResponse store = storeService.toggleStoreStatus();
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật trạng thái cửa hàng thành công", store)
        );
    }

    /**
     * Xóa cửa hàng của user hiện tại
     * DELETE /api/stores
     * Yêu cầu: User đã đăng nhập và là chủ cửa hàng
     */
    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> deleteStore() {
        
        log.info("DELETE /api/stores - Delete current user's store");
        
        storeService.deleteStore();
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa cửa hàng thành công", null)
        );
    }

    /**
     * Xóa cửa hàng theo ID (Admin only)
     * DELETE /api/stores/{storeId}
     * Yêu cầu: ADMIN
     */
    @DeleteMapping("/{storeId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteStoreById(
            @PathVariable Long storeId) {
        
        log.info("DELETE /api/stores/{} - Delete store by ID (Admin)", storeId);
        
        storeService.deleteStoreById(storeId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa cửa hàng thành công", null)
        );
    }

}