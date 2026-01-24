package com.grocery.server.store.service;

import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.store.dto.request.CreateStoreRequest;
import com.grocery.server.store.dto.request.UpdateStoreRequest;
import com.grocery.server.store.dto.response.StoreListResponse;
import com.grocery.server.store.dto.response.StoreResponse;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service: StoreService
 * Mục đích: Xử lý business logic cho Store module
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StoreService {

    private final StoreRepository storeRepository;
    private final UserRepository userRepository;

    @Transactional
    public StoreResponse createStore(CreateStoreRequest request) {
        User currentUser = getCurrentUser();
        
        // Kiểm tra user có role STORE không
        if (currentUser.getRole() != User.UserRole.STORE) {
            throw new BadRequestException("Chỉ tài khoản STORE mới có thể tạo cửa hàng");
        }
        
        // Kiểm tra user đã có cửa hàng chưa (1 user chỉ có 1 store)
        if (storeRepository.existsByOwnerId(currentUser.getId())) {
            throw new BadRequestException("Bạn đã có cửa hàng rồi");
        }
        
        // Tạo store mới
        Store store = Store.builder()
                .owner(currentUser)
                .storeName(request.getStoreName())
                .address(request.getAddress())
                .phoneNumber(request.getPhoneNumber())
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .isOpen(true)
                .build();
        
        Store savedStore = storeRepository.save(store);
        log.info("Created store: {} for user: {}", savedStore.getStoreName(), currentUser.getPhoneNumber());
        
        return StoreResponse.fromEntity(savedStore);
    }

    @Transactional
    public StoreResponse updateStore(Long storeId, UpdateStoreRequest request) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
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
        }
        
        Store updatedStore = storeRepository.save(store);
        log.info("Updated store: {}", updatedStore.getId());
        
        return StoreResponse.fromEntity(updatedStore);
    }

    public StoreResponse getMyStore() {
        User currentUser = getCurrentUser();
        
        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có cửa hàng"));
        
        return StoreResponse.fromEntity(store);
    }

    public StoreResponse getStoreById(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        return StoreResponse.fromEntity(store);
    }

    public List<StoreListResponse> getAllStores() {
        return storeRepository.findAll().stream()
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<StoreListResponse> getOpenStores() {
        return storeRepository.findByIsOpen(true).stream()
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<StoreListResponse> searchStores(String keyword) {
        return storeRepository.findByStoreNameContainingIgnoreCase(keyword).stream()
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public StoreResponse toggleStoreStatus(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền sở hữu
        if (!store.getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền thay đổi trạng thái cửa hàng này");
        }
        
        // Toggle status
        store.setIsOpen(!store.getIsOpen());
        Store updatedStore = storeRepository.save(store);
        
        log.info("Toggled store status: {} to {}", storeId, updatedStore.getIsOpen());
        
        return StoreResponse.fromEntity(updatedStore);
    }

    @Transactional
    public void deleteStore(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền: owner hoặc admin
        if (!store.getOwner().getId().equals(currentUser.getId()) 
                && currentUser.getRole() != User.UserRole.ADMIN) {
            throw new UnauthorizedException("Bạn không có quyền xóa cửa hàng này");
        }
        
        storeRepository.delete(store);
        log.info("Deleted store: {}", storeId);
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String phoneNumber = authentication.getName();
        
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UnauthorizedException("User không tồn tại hoặc đã bị xóa"));
    }
}
