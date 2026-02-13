package com.grocery.server.auth.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

/**
 * Component: JwtTokenProvider
 * Mục đích: Tạo và validate JWT token
 */
@Component
@Slf4j
public class JwtTokenProvider {
    
    /**
     * Secret key (Base64 encoded) - Được config trong application.properties
     */
    @Value("${app.jwt.secret}")
    private String jwtSecret;
    
    /**
     * Token expiration time (milliseconds) - Được config trong application.properties
     */
    @Value("${app.jwt.expiration}") 
    private long jwtExpirationMs;
    
    private SecretKey key;
    
    @PostConstruct
    public void init() {
        // Tạo key từ secret string
        byte[] keyBytes = Decoders.BASE64.decode(jwtSecret);
        this.key = Keys.hmacShaKeyFor(keyBytes);
    }
    
    /**
     * Tạo JWT token từ phone number
     * @param phoneNumber Số điện thoại của user
     * @return JWT token string
     */
    public String generateToken(String phoneNumber) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationMs);
        
        return Jwts.builder()
                .subject(phoneNumber)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key, Jwts.SIG.HS512)
                .compact();
    }
    
    /**
     * Lấy phone number từ JWT token
     * @param token JWT token
     * @return Phone number
     */
    public String getPhoneNumberFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
        
        return claims.getSubject();
    }
    
    /**
     * Validate JWT token
     * @param token JWT token
     * @return true nếu token hợp lệ
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (MalformedJwtException ex) {
            log.error("Invalid JWT token: {}", ex.getMessage());
        } catch (ExpiredJwtException ex) {
            log.error("Expired JWT token: {}", ex.getMessage());
        } catch (UnsupportedJwtException ex) {
            log.error("Unsupported JWT token: {}", ex.getMessage());
        } catch (IllegalArgumentException ex) {
            log.error("JWT claims string is empty: {}", ex.getMessage());
        }
        return false;
    }
}
