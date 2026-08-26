package com.gamelearn.auth;

import java.io.IOException;
import java.util.UUID;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.UserStatus;
import com.gamelearn.repository.UserRepository;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Extracts a Bearer token, verifies it cryptographically and resolves the
 * authoritative user from the database. A token is only accepted when its
 * subject exists and the account is ACTIVE; suspended or deleted accounts
 * cannot use previously issued tokens. Failures leave the context empty so
 * the security chain answers 401.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtService jwtService;
    private final UserRepository userRepository;

    public JwtAuthenticationFilter(JwtService jwtService, UserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith(BEARER_PREFIX)
                && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                Claims claims = jwtService.parseAndValidate(header.substring(BEARER_PREFIX.length()));
                User user = userRepository.findById(UUID.fromString(claims.getSubject())).orElse(null);
                if (user != null && user.getStatus() == UserStatus.ACTIVE) {
                    AuthenticatedUser principal =
                            new AuthenticatedUser(user.getId(), user.getEmail(), user.getDisplayName());
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            principal, null, principal.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (IllegalArgumentException | JwtException rejected) {
                // Invalid/expired/malformed token or unknown subject:
                // leave the security context empty; the entry point responds 401.
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }
}
