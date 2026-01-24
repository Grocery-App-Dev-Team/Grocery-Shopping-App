package com.grocery.server.store.service;

import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.BadRequestException;
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

    /**
     * Tạo cửa hàng mới
     */
    @Transactional
    public StoreResponse createStore(CreateStoreRequest request) {
        log.info("Creating new store: {}", request.getStoreName());

        // Lấy user hiện tại
        User currentUser = getCurrentUser();

        // Kiểm tra user đã có cửa hàng chưa
        if (storeRepository.existsByOwnerId(currentUser.getId())) {
            throw new BadRequestException("Bạn đã có cửa hàng rồi. Mỗi user chỉ được tạo 1 cửa hàng.");
        }

        // Kiểm tra tên cửa hàng đã tồn tại chưa
        if (storeRepository.findByStoreName(request.getStoreName()).isPresent()) {
            throw new BadRequestException("Tên cửa hàng đã tồn tại");
        }

        // Tạo store mới
        Store store = Store.builder()
                .owner(currentUser)
                .storeName(request.getStoreName())
                .address(request.getAddress())
                .isOpen(true)
                .build();

        Store savedStore = storeRepository.save(store);
        log.info("Store created successfully with ID: {}", savedStore.getId());

        return StoreResponse.fromEntity(savedStore);
    }

    /**
     * Lấy thông tin cửa hàng của user hiện tại
     */
    public StoreResponse getMyStore() {
        log.info("Getting current user's store");
        User currentUser = getCurrentUser();

        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có cửa hàng"));

        return StoreResponse.fromEntity(store);
    }

    /**
     * Lấy thông tin cửa hàng theo ID
     */
    public StoreResponse getStoreById(Long storeId) {
        log.info("Getting store by ID: {}", storeId);

        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy cửa hàng với ID: " + storeId));

        return StoreResponse.fromEntity(store);
    }

    /**
     * Lấy tất cả cửa hàng
     */
    public List<StoreListResponse> getAllStores() {
        log.info("Getting all stores");

        List<Store> stores = storeRepository.findAll();

        return stores.stream()
                .map(StoreListResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Cập nhật thông tin cửa hàng
     */
    @Transactional
    public StoreResponse updateStore(UpdateStoreRequest request) {
        log.info("Updating store");

        User currentUser = getCurrentUser();

        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có cửa hàng"));

        // Cập nhật các trường
        if (request.getStoreName() != null && !request.getStoreName().isBlank()) {
            // Kiểm tra tên mới có trùng với cửa hàng khác không
            storeRepository.findByStoreName(request.getStoreName())
                    .ifPresent(existingStore -> {
                        if (!existingStore.getId().equals(store.getId())) {
                            throw new BadRequestException("Tên cửa hàng đã tồn tại");
                        }
                    });
            store.setStoreName(request.getStoreName());
        }

        if (request.getAddress() != null && !request.getAddress().isBlank()) {
            store.setAddress(request.getAddress());
        }

        Store updatedStore = storeRepository.save(store);
        log.info("Store updated successfully with ID: {}", updatedStore.getId());

        return StoreResponse.fromEntity(updatedStore);
    }

    /**
     * Toggle trạng thái mở/đóng cửa hàng
     */
    @Transactional
    public StoreResponse toggleStoreStatus() {
        log.info("Toggling store status");

        User currentUser = getCurrentUser();

        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có cửa hàng"));

        store.setIsOpen(!store.getIsOpen());

        Store updatedStore = storeRepository.save(store);
        log.info("Store status toggled. New status: {}", updatedStore.getIsOpen());

        return StoreResponse.fromEntity(updatedStore);
    }

    /**
     * Xóa cửa hàng
     */
    @Transactional
    public void deleteStore() {
        log.info("Deleting store");

        User currentUser = getCurrentUser();

        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa có cửa hàng"));

        storeRepository.delete(store);
        log.info("Store deleted successfully with ID: {}", store.getId());
    }

    /**
     * Xóa cửa hàng theo ID (Admin)
     */
    @Transactional
    public void deleteStoreById(Long storeId) {
        log.info("Deleting store by ID: {}", storeId);

        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy cửa hàng với ID: " + storeId));

        storeRepository.delete(store);
        log.info("Store deleted successfully with ID: {}", storeId);
    }

    /**
     * Lấy user hiện tại từ Security Context
     */
    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy user"));
    }

}