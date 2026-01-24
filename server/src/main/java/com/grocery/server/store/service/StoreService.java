package com.grocery.server.store.service;

import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
<<<<<<< Updated upstream
import com.grocery.server.store.dto.request.CreateStoreRequest;
=======
>>>>>>> Stashed changes
import com.grocery.server.store.dto.request.UpdateStoreRequest;
import com.grocery.server.store.dto.response.StoreListResponse;
import com.grocery.server.store.dto.response.StoreResponse;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
<<<<<<< Updated upstream
import org.springframework.security.core.Authentication;
=======
>>>>>>> Stashed changes
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service: StoreService
<<<<<<< Updated upstream
 * Mục đích: Xử lý business logic cho Store module
=======
 * Mô tả: Xử lý business logic cho Store
>>>>>>> Stashed changes
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StoreService {

    private final StoreRepository storeRepository;
    private final UserRepository userRepository;

    /**
     * NOTE: Method createStore() đã bị XÓA
     * 
     * Lý do: Store được tự động tạo trong quá trình đăng ký (AuthService.register)
     * khi user chọn role = STORE.
     * 
     * Flow mới:
     * 1. Frontend: User chọn "Đăng ký với tư cách cửa hàng"
     * 2. Frontend: Hiển thị form bao gồm thông tin User + Store
     * 3. Frontend: Gửi POST /api/auth/register với đầy đủ thông tin
     * 4. Backend: AuthService.register() tự động tạo User và Store
     */

<<<<<<< Updated upstream
=======
    /**
     * Cập nhật thông tin cửa hàng (chỉ owner mới được phép)
     */
>>>>>>> Stashed changes
    @Transactional
    public StoreResponse updateStore(Long storeId, UpdateStoreRequest request) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
<<<<<<< Updated upstream
        // Kiểm tra quyền sở hữu
        if (!store.getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền chỉnh sửa cửa hàng này");
        }
        
        // Cập nhật thông tin
        store.setStoreName(request.getStoreName());
        store.setAddress(request.getAddress());
        store.setPhoneNumber(request.getPhoneNumber());
        store.setDescription(request.getDescription());
        
        if (request.getImageUrl() != null && !request.getImageUrl().isEmpty()) {
            store.setImageUrl(request.getImageUrl());
=======
        // Kiểm tra quyền: chỉ owner mới được cập nhật
        if (!store.getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền cập nhật cửa hàng này");
        }
        
        // Cập nhật thông tin
        if (request.getStoreName() != null && !request.getStoreName().trim().isEmpty()) {
            store.setStoreName(request.getStoreName());
        }
        
        if (request.getAddress() != null && !request.getAddress().trim().isEmpty()) {
            store.setAddress(request.getAddress());
>>>>>>> Stashed changes
        }
        
        Store updatedStore = storeRepository.save(store);
        log.info("Updated store: {}", updatedStore.getId());
        
        return StoreResponse.fromEntity(updatedStore);
    }

<<<<<<< Updated upstream
=======
    /**
     * Lấy thông tin cửa hàng của mình (dành cho store owner)
     */
>>>>>>> Stashed changes
    public StoreResponse getMyStore() {
        User currentUser = getCurrentUser();
        
        Store store = storeRepository.findByOwnerId(currentUser.getId())
<<<<<<< Updated upstream
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có cửa hàng"));
=======
                .orElseThrow(() -> new ResourceNotFoundException("Store", "ownerId", currentUser.getId()));
>>>>>>> Stashed changes
        
        return StoreResponse.fromEntity(store);
    }

<<<<<<< Updated upstream
=======
    /**
     * Lấy thông tin chi tiết 1 cửa hàng (public)
     */
>>>>>>> Stashed changes
    public StoreResponse getStoreById(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        return StoreResponse.fromEntity(store);
    }

<<<<<<< Updated upstream
    public List<StoreListResponse> getAllStores() {
        return storeRepository.findAll().stream()
=======
    /**
     * Lấy danh sách tất cả cửa hàng (public)
     */
    public List<StoreListResponse> getAllStores() {
        List<Store> stores = storeRepository.findAll();
        
        return stores.stream()
>>>>>>> Stashed changes
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

<<<<<<< Updated upstream
    public List<StoreListResponse> getOpenStores() {
        return storeRepository.findByIsOpen(true).stream()
=======
    /**
     * Lấy danh sách cửa hàng đang mở cửa (public)
     */
    public List<StoreListResponse> getOpenStores() {
        List<Store> stores = storeRepository.findByIsOpen(true);
        
        return stores.stream()
>>>>>>> Stashed changes
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

<<<<<<< Updated upstream
    public List<StoreListResponse> searchStores(String keyword) {
        return storeRepository.findByStoreNameContainingIgnoreCase(keyword).stream()
=======
    /**
     * Tìm kiếm cửa hàng theo tên hoặc địa chỉ (public)
     */
    public List<StoreListResponse> searchStores(String keyword) {
        List<Store> stores = storeRepository.findByStoreNameContainingIgnoreCase(keyword);
        
        // Nếu không tìm thấy theo tên, thử tìm theo địa chỉ
        if (stores.isEmpty()) {
            stores = storeRepository.findByAddressContainingIgnoreCase(keyword);
        }
        
        return stores.stream()
>>>>>>> Stashed changes
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

<<<<<<< Updated upstream
=======
    /**
     * Mở/đóng cửa hàng (chỉ owner)
     */
>>>>>>> Stashed changes
    @Transactional
    public StoreResponse toggleStoreStatus(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
<<<<<<< Updated upstream
        // Kiểm tra quyền sở hữu
=======
        // Kiểm tra quyền: chỉ owner mới được toggle
>>>>>>> Stashed changes
        if (!store.getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền thay đổi trạng thái cửa hàng này");
        }
        
<<<<<<< Updated upstream
        // Toggle status
=======
        // Toggle trạng thái
>>>>>>> Stashed changes
        store.setIsOpen(!store.getIsOpen());
        Store updatedStore = storeRepository.save(store);
        
        log.info("Toggled store status: {} to {}", storeId, updatedStore.getIsOpen());
        
        return StoreResponse.fromEntity(updatedStore);
    }

<<<<<<< Updated upstream
=======
    /**
     * Xóa cửa hàng (chỉ owner hoặc admin)
     */
>>>>>>> Stashed changes
    @Transactional
    public void deleteStore(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
<<<<<<< Updated upstream
        // Kiểm tra quyền: owner hoặc admin
        if (!store.getOwner().getId().equals(currentUser.getId()) 
                && currentUser.getRole() != User.UserRole.ADMIN) {
=======
        // Kiểm tra quyền: chỉ owner hoặc admin mới được xóa
        boolean isOwner = store.getOwner().getId().equals(currentUser.getId());
        boolean isAdmin = currentUser.getRole() == User.UserRole.ADMIN;
        
        if (!isOwner && !isAdmin) {
>>>>>>> Stashed changes
            throw new UnauthorizedException("Bạn không có quyền xóa cửa hàng này");
        }
        
        storeRepository.delete(store);
        log.info("Deleted store: {}", storeId);
    }

<<<<<<< Updated upstream
    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UnauthorizedException("User không tồn tại hoặc đã bị xóa"));
=======
    /**
     * Helper: Lấy thông tin user hiện tại từ SecurityContext
     */
    private User getCurrentUser() {
        String phoneNumber = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ResourceNotFoundException("User", "phoneNumber", phoneNumber));
>>>>>>> Stashed changes
    }
}
