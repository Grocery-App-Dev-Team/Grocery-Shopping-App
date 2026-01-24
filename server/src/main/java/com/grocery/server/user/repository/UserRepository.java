package com.grocery.server.user.repository;

import com.grocery.server.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository: UserRepository
 * Mục đích: Truy vấn database cho bảng users
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    /**
     * Tìm user theo số điện thoại (dùng để login)
     * @param phoneNumber Số điện thoại
     * @return Optional<User>
     */
    Optional<User> findByPhoneNumber(String phoneNumber);
    
    /**
     * Kiểm tra số điện thoại đã tồn tại chưa
     * @param phoneNumber Số điện thoại
     * @return true nếu đã tồn tại
     */
    boolean existsByPhoneNumber(String phoneNumber);
    
    /**
     * Tìm user theo role
     * @param role Role của user
     * @return Danh sách users
     */
    java.util.List<User> findByRole(User.UserRole role);
    
    /**
     * Tìm user theo status
     * @param status Status của user
     * @return Danh sách users
     */
    java.util.List<User> findByStatus(User.UserStatus status);
}
