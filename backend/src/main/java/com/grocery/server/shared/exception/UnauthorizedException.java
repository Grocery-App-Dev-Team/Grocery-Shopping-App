package com.grocery.server.shared.exception;

/**
 * Exception: UnauthorizedException
 * Mục đích: Ném ra khi không có quyền truy cập
 */
public class UnauthorizedException extends RuntimeException {
    
    public UnauthorizedException(String message) {
        super(message);
    }
}
