package com.grocery.server.store.repository;

import com.grocery.server.store.entity.Store;
import com.grocery.server.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository: StoreRepository
<<<<<<< Updated upstream
 * Mục đích: Truy vấn database cho bảng stores
 */
@Repository
public interface StoreRepository extends JpaRepository<Store, Long> {
    Optional<Store> findByStoreName(String storeName);
    Optional<Store> findByOwner(User owner);
    Optional<Store> findByOwnerId(Long ownerId);
    boolean existsByOwnerId(Long ownerId);
    List<Store> findByIsOpen(Boolean isOpen);
    List<Store> findByStoreNameContainingIgnoreCase(String keyword);
=======
 * Mô tả: Truy vấn database cho Store entity
 */
@Repository
public interface StoreRepository extends JpaRepository<Store, Long> {
    
    /**
     * Tìm store theo tên
     */
    Optional<Store> findByStoreName(String storeName);
    
    /**
     * Tìm store theo owner (User)
     */
    Optional<Store> findByOwner(User owner);
    
    /**
     * Tìm store theo owner ID
     */
    Optional<Store> findByOwnerId(Long ownerId);
    
    /**
     * Kiểm tra user đã có store chưa (dùng cho validation one-store-per-user)
     */
    boolean existsByOwnerId(Long ownerId);
    
    /**
     * Tìm stores theo trạng thái mở/đóng
     */
    List<Store> findByIsOpen(Boolean isOpen);
    
    /**
     * Tìm kiếm store theo tên (contains, ignore case)
     */
    List<Store> findByStoreNameContainingIgnoreCase(String keyword);
    
    /**
     * Tìm kiếm store theo địa chỉ (contains, ignore case)
     */
>>>>>>> Stashed changes
    List<Store> findByAddressContainingIgnoreCase(String keyword);
}
