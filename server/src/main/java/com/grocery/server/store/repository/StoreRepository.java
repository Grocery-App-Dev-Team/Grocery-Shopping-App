package com.grocery.server.store.repository;

import com.grocery.server.store.entity.Store;
import com.grocery.server.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository: StoreRepository
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
    List<Store> findByAddressContainingIgnoreCase(String keyword);
}
