package com.grocery.server.auth.security;

import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.Collections;

/**
 * Service: CustomUserDetailsService
 * Mục đích: Load user từ database cho Spring Security
 */
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {
    
    private final UserRepository userRepository;
    
    @Override
    @Transactional
    public UserDetails loadUserByUsername(String phoneNumber) throws UsernameNotFoundException {
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "Không tìm thấy user với số điện thoại: " + phoneNumber));
        
        return new org.springframework.security.core.userdetails.User(
                user.getPhoneNumber(),
                user.getPasswordHash(),
                user.getStatus() == User.UserStatus.ACTIVE,
                true,
                true,
                true,
                getAuthorities(user)
        );
    }
    
    /**
     * Lấy quyền của user (role)
     */
    private Collection<? extends GrantedAuthority> getAuthorities(User user) {
        return Collections.singletonList(
                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );
    }
}
