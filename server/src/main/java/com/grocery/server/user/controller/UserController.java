package com.grocery.server.user.controller;

import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.user.dto.request.ChangePasswordRequest;
import com.grocery.server.user.dto.request.UpdateProfileRequest;
import com.grocery.server.user.dto.response.UserListResponse;
import com.grocery.server.user.dto.response.UserProfileResponse;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller: UserController
 * Mục đích: REST API cho User module
 * 
 * Base URL: /api/users
 */
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
@Slf4j
public class UserController {

    private final UserService userService;

    // ========== CUSTOMER/SHIPPER/STORE - USER PROFILE ==========

    /**
     * GET /api/users/profile
     * Lấy thông tin profile của user hiện tại
     * 
     * Authorization: Bearer token (bất kỳ role nào đã login)
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Lấy thông tin profile thành công",
     *   "data": {
     *     "id": 1,
     *     "phoneNumber": "0901234567",
     *     "fullName": "Nguyễn Văn A",
     *     "avatarUrl": "https://...",
     *     "address": "123 Đường ABC",
     *     "role": "CUSTOMER",
     *     "status": "ACTIVE",
     *     "createdAt": "2024-01-01T10:00:00",
     *     "updatedAt": "2024-01-02T15:30:00"
     *   }
     * }
     */
    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getCurrentUserProfile() {
        log.info("GET /api/users/profile - Get current user profile");
        
        UserProfileResponse profile = userService.getCurrentUserProfile();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin profile thành công", profile)
        );
    }

    /**
     * PUT /api/users/profile
     * Cập nhật thông tin profile
     * 
     * Authorization: Bearer token (bất kỳ role nào đã login)
     * 
     * Request Body:
     * {
     *   "fullName": "Nguyễn Văn B",
     *   "address": "456 Đường XYZ",
     *   "avatarUrl": "https://..."
     * }
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Cập nhật profile thành công",
     *   "data": { ... }
     * }
     */
    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request) {
        
        log.info("PUT /api/users/profile - Update profile");
        
        UserProfileResponse profile = userService.updateProfile(request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật profile thành công", profile)
        );
    }

    /**
     * POST /api/users/change-password
     * Đổi mật khẩu
     * 
     * Authorization: Bearer token (bất kỳ role nào đã login)
     * 
     * Request Body:
     * {
     *   "oldPassword": "123456",
     *   "newPassword": "newpass123",
     *   "confirmPassword": "newpass123"
     * }
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Đổi mật khẩu thành công",
     *   "data": null
     * }
     */
    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request) {
        
        log.info("POST /api/users/change-password - Change password");
        
        userService.changePassword(request);
        
        return ResponseEntity.ok(
                ApiResponse.success("Đổi mật khẩu thành công", null)
        );
    }

    // ========== ADMIN - USER MANAGEMENT ==========

    /**
     * GET /api/users
     * Lấy danh sách tất cả users
     * 
     * Authorization: Bearer token (ADMIN only)
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Lấy danh sách users thành công",
     *   "data": [
     *     {
     *       "id": 1,
     *       "phoneNumber": "0901234567",
     *       "fullName": "Nguyễn Văn A",
     *       "role": "CUSTOMER",
     *       "status": "ACTIVE"
     *     },
     *     ...
     *   ]
     * }
     */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<UserListResponse>>> getAllUsers() {
        log.info("GET /api/users - Get all users (Admin)");
        
        List<UserListResponse> users = userService.getAllUsers();
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách users thành công", users)
        );
    }

    /**
     * GET /api/users/role/{role}
     * Lấy danh sách users theo role
     * 
     * Authorization: Bearer token (ADMIN only)
     * 
     * Path Variable: role (CUSTOMER, SHIPPER, STORE, ADMIN)
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Lấy danh sách users theo role thành công",
     *   "data": [ ... ]
     * }
     */
    @GetMapping("/role/{role}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<UserListResponse>>> getUsersByRole(
            @PathVariable String role) {
        
        log.info("GET /api/users/role/{} - Get users by role (Admin)", role);
        
        User.UserRole userRole = User.UserRole.valueOf(role.toUpperCase());
        List<UserListResponse> users = userService.getUsersByRole(userRole);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy danh sách users theo role thành công", users)
        );
    }

    /**
     * GET /api/users/{userId}
     * Lấy thông tin chi tiết user theo ID
     * 
     * Authorization: Bearer token (ADMIN only)
     * 
     * Path Variable: userId
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Lấy thông tin user thành công",
     *   "data": { ... }
     * }
     */
    @GetMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getUserById(
            @PathVariable Long userId) {
        
        log.info("GET /api/users/{} - Get user by ID (Admin)", userId);
        
        UserProfileResponse user = userService.getUserById(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Lấy thông tin user thành công", user)
        );
    }

    /**
     * PATCH /api/users/{userId}/toggle-status
     * Cấm/Mở khóa user
     * 
     * Authorization: Bearer token (ADMIN only)
     * 
     * Path Variable: userId
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Cập nhật trạng thái user thành công",
     *   "data": { ... }
     * }
     */
    @PatchMapping("/{userId}/toggle-status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserProfileResponse>> toggleUserStatus(
            @PathVariable Long userId) {
        
        log.info("PATCH /api/users/{}/toggle-status - Toggle user status (Admin)", userId);
        
        UserProfileResponse user = userService.toggleUserStatus(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Cập nhật trạng thái user thành công", user)
        );
    }

    /**
     * DELETE /api/users/{userId}
     * Xóa user
     * 
     * Authorization: Bearer token (ADMIN only)
     * 
     * Path Variable: userId
     * 
     * Response:
     * {
     *   "success": true,
     *   "message": "Xóa user thành công",
     *   "data": null
     * }
     */
    @DeleteMapping("/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteUser(
            @PathVariable Long userId) {
        
        log.info("DELETE /api/users/{} - Delete user (Admin)", userId);
        
        userService.deleteUser(userId);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa user thành công", null)
        );
    }
}
