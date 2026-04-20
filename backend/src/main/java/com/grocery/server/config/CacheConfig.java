package com.grocery.server.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Configuration: CacheConfig
 * Mô tả: Cấu hình Caffeine Cache cho ứng dụng
 * 
 * Các cache được quản lý:
 * - categories: Danh mục sản phẩm (ít thay đổi)
 * - units: Đơn vị tính (gần như không đổi) 
 * - unitCategories: Nhóm đơn vị tính
 * - storeRatings: Điểm đánh giá trung bình cửa hàng
 */
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager(
            "categories",       // Cache danh mục sản phẩm
            "units",            // Cache đơn vị tính
            "unitCategories",   // Cache nhóm đơn vị tính
            "storeRatings"      // Cache rating cửa hàng
        );
        
        cacheManager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(500)                       // Tối đa 500 entries
            .expireAfterWrite(5, TimeUnit.MINUTES)  // Hết hạn sau 5 phút
            .recordStats()                          // Ghi thống kê cache (debug)
        );
        
        return cacheManager;
    }
}
