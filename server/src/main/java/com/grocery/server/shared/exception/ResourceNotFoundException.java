package com.grocery.server.shared.exception;

/**
 * Exception: ResourceNotFoundException
 * Mục đích: Ném ra khi không tìm thấy resource
 */
public class ResourceNotFoundException extends RuntimeException {
    
    public ResourceNotFoundException(String message) {
        super(message);
    }
    
    public ResourceNotFoundException(String resourceName, String fieldName, Object fieldValue) {
        super(String.format("%s not found with %s: '%s'", resourceName, fieldName, fieldValue));
    }
}
