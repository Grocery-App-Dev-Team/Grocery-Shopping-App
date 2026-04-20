package com.grocery.server.store.service;

import com.grocery.server.shared.exception.BadRequestException;
import com.grocery.server.shared.exception.ResourceNotFoundException;
import com.grocery.server.shared.exception.UnauthorizedException;
import com.grocery.server.store.dto.request.UpdateStoreRequest;
import com.grocery.server.store.dto.response.StoreListResponse;
import com.grocery.server.store.dto.response.StoreResponse;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import com.grocery.server.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service: StoreService
 * Mô tả: Xử lý business logic cho Store
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StoreService {

    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;

    /**
     * Cập nhật thông tin cửa hàng (chỉ owner mới được phép)
     */
    @Transactional
    public StoreResponse updateStore(Long storeId, UpdateStoreRequest request) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));

        User currentUser = getCurrentUser();

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
        }

        if (request.getImageUrl() != null && !request.getImageUrl().trim().isEmpty()) {
            store.setImageUrl(request.getImageUrl().trim());
        }

        Store updatedStore = storeRepository.save(store);
        log.info("Updated store: {}", updatedStore.getId());

        Double avgRating = reviewRepository.calculateAverageRating(storeId);
        Long totalReviews = reviewRepository.countByStoreId(storeId);
        return StoreResponse.fromEntity(updatedStore, avgRating, totalReviews);
    }

    /**
     * Lấy thông tin cửa hàng của mình
     */
    @Transactional(readOnly = true)
    public StoreResponse getMyStore() {
        User currentUser = getCurrentUser();

        Store store = storeRepository.findByOwnerId(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Store", "ownerId", currentUser.getId()));

        Double avgRating = reviewRepository.calculateAverageRating(store.getId());
        Long totalReviews = reviewRepository.countByStoreId(store.getId());
        return StoreResponse.fromEntity(store, avgRating, totalReviews);
    }

    /**
     * Lấy thông tin chi tiết 1 cửa hàng (public)
     */
    @Transactional(readOnly = true)
    public StoreResponse getStoreById(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));

        Double avgRating = reviewRepository.calculateAverageRating(storeId);
        Long totalReviews = reviewRepository.countByStoreId(storeId);
        return StoreResponse.fromEntity(store, avgRating, totalReviews);
    }

    /**
     * Lấy danh sách tất cả cửa hàng (public)
     */
    @Transactional(readOnly = true)
    public List<StoreListResponse> getAllStores() {
        List<Store> stores = storeRepository.findAll();
        Map<Long, Object[]> ratingMap = buildRatingMap(reviewRepository.calculateAllStoreRatings());

        return stores.stream()
                .map(store -> {
                    Object[] rating = ratingMap.get(store.getId());
                    Double avgRating = rating != null ? (Double) rating[1] : null;
                    Long totalReviews = rating != null ? (Long) rating[2] : 0L;
                    return StoreListResponse.fromEntity(store, avgRating, totalReviews);
                })
                .collect(Collectors.toList());
    }

    /**
     * Lấy danh sách cửa hàng đang mở cửa (public)
     */
    @Transactional(readOnly = true)
    public List<StoreListResponse> getOpenStores() {
        List<Store> stores = storeRepository.findByIsOpen(true);
        Map<Long, Object[]> ratingMap = buildRatingMapForStores(stores);

        return stores.stream()
                .map(store -> {
                    Object[] rating = ratingMap.get(store.getId());
                    Double avgRating = rating != null ? (Double) rating[1] : null;
                    Long totalReviews = rating != null ? (Long) rating[2] : 0L;
                    return StoreListResponse.fromEntity(store, avgRating, totalReviews);
                })
                .collect(Collectors.toList());
    }

    /**
     * Tìm kiếm cửa hàng theo tên hoặc địa chỉ (public)
     */
    @Transactional(readOnly = true)
    public List<StoreListResponse> searchStores(String keyword) {
        List<Store> stores = storeRepository.findByStoreNameContainingIgnoreCase(keyword);

        // Nếu không tìm thấy theo tên, thử tìm theo địa chỉ
        if (stores.isEmpty()) {
            stores = storeRepository.findByAddressContainingIgnoreCase(keyword);
        }

        Map<Long, Object[]> ratingMap = buildRatingMapForStores(stores);

        return stores.stream()
                .map(store -> {
                    Object[] rating = ratingMap.get(store.getId());
                    Double avgRating = rating != null ? (Double) rating[1] : null;
                    Long totalReviews = rating != null ? (Long) rating[2] : 0L;
                    return StoreListResponse.fromEntity(store, avgRating, totalReviews);
                })
                .collect(Collectors.toList());
    }

    /**
     * Mở/đóng cửa hàng (chỉ owner)
     */
    @Transactional
    public StoreResponse toggleStoreStatus(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));

        User currentUser = getCurrentUser();

        // Kiểm tra quyền: chỉ owner mới được toggle
        if (!store.getOwner().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Bạn không có quyền thay đổi trạng thái cửa hàng này");
        }

        // Toggle trạng thái
        store.setIsOpen(!store.getIsOpen());
        Store updatedStore = storeRepository.save(store);

        log.info("Toggled store status: {} to {}", storeId, updatedStore.getIsOpen());

        Double avgRating = reviewRepository.calculateAverageRating(storeId);
        Long totalReviews = reviewRepository.countByStoreId(storeId);
        return StoreResponse.fromEntity(updatedStore, avgRating, totalReviews);
    }

    /**
     * Xóa cửa hàng (chỉ owner hoặc admin)
     */
    @Transactional
    public void deleteStore(Long storeId) {
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Store", "id", storeId));
        
        User currentUser = getCurrentUser();
        
        // Kiểm tra quyền: chỉ owner hoặc admin mới được xóa
        boolean isOwner = store.getOwner().getId().equals(currentUser.getId());
        boolean isAdmin = currentUser.getRole() == User.UserRole.ADMIN;
        
        if (!isOwner && !isAdmin) {
            throw new UnauthorizedException("Bạn không có quyền xóa cửa hàng này");
        }
        
        storeRepository.delete(store);
        log.info("Deleted store: {}", storeId);
    }

    /**
     * Helper: Lấy thông tin user hiện tại từ SecurityContext
     */
    private User getCurrentUser() {
        String phoneNumber = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ResourceNotFoundException("User", "phoneNumber", phoneNumber));
    }

    /**
     * Helper: Build rating map từ kết quả batch query của ReviewRepository
     * @param ratingRows List<Object[]> với mỗi row = [storeId, avgRating, totalReviews]
     * @return Map<storeId, Object[]>
     */
    private Map<Long, Object[]> buildRatingMap(List<Object[]> ratingRows) {
        return ratingRows.stream().collect(Collectors.toMap(
                row -> (Long) row[0],
                row -> row
        ));
    }

    /**
     * Helper: Build rating map cho danh sách stores cụ thể
     * Sử dụng query với IN clause thay vì lấy tất cả
     */
    private Map<Long, Object[]> buildRatingMapForStores(List<Store> stores) {
        if (stores.isEmpty()) {
            return Map.of();
        }
        List<Long> storeIds = stores.stream().map(Store::getId).collect(Collectors.toList());
        return buildRatingMap(reviewRepository.calculateRatingsForStores(storeIds));
    }
}
