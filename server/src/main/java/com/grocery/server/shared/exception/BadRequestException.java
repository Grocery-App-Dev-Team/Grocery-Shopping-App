package com.grocery.server.shared.exception;

/**
 * Exception: BadRequestException
 * Mục đích: Ném ra khi request không hợp lệ
 */
public class BadRequestException extends RuntimeException {
    
    public BadRequestException(String message) {
        super(message);
    }
}
