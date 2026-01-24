package com.grocery.server.shared.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO: ApiResponse
 * Mục đích: Chuẩn hóa format response trả về client
 * 
 * Format chuẩn:
 * {
 *   "success": true,
 *   "message": "Thành công",
 *   "data": { ... }
 * }
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiResponse<T> {
    
    /**
     * Trạng thái thành công/thất bại
     */
    private boolean success;
    
    /**
     * Thông báo cho user
     */
    private String message;
    
    /**
     * Dữ liệu trả về (Generic type)
     */
    private T data;
    
    /**
     * Mã lỗi (nếu có)
     */
    private String errorCode;
    
    // ========== HELPER METHODS ==========
    
    /**
     * Response thành công với data
     */
    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message("Thành công")
                .data(data)
                .build();
    }
    
    /**
     * Response thành công với message tùy chỉnh
     */
    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .build();
    }
    
    /**
     * Response thất bại
     */
    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .build();
    }
    
    /**
     * Response thất bại với error code
     */
    public static <T> ApiResponse<T> error(String message, String errorCode) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .errorCode(errorCode)
                .build();
    }
}
