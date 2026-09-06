package com.gamelearn.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.auth.JwtService;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.LoginRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.UserStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.entity.UserCredit;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.UserCreditRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Authentication use cases: register, login, validate.
 *
 * <p>Registration is atomic — user row and learner profile row are created
 * in one transaction; a failure leaves no partial account behind.</p>
 *
 * <p>Login never reveals whether an email exists, the password was wrong or
 * the account is suspended: every failure is the identical generic 401.</p>
 */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final LearnerProfileRepository learnerProfileRepository;
    private final UserCreditRepository userCreditRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       LearnerProfileRepository learnerProfileRepository,
                       UserCreditRepository userCreditRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.userCreditRepository = userCreditRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ApiException(409, "DATA_CONFLICT",
                    "An account with this email already exists");
        }

        User user = new User();
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(request.displayName().trim());
        user.setStatus(UserStatus.ACTIVE);
        user = userRepository.saveAndFlush(user);

        // One profile per user, created inside the same transaction.
        LearnerProfile profile = new LearnerProfile();
        profile.setUser(user);
        learnerProfileRepository.save(profile);

        // Phase L1: pre-create credits row so concurrent game submissions never race on lazy creation.
        UserCredit credit = new UserCredit();
        credit.setUser(user);
        credit.setBalance(0);
        userCreditRepository.save(credit);

        return buildAuthResponse(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();
        User user = userRepository.findByEmail(normalizedEmail).orElse(null);
        boolean passwordMatches = user != null
                && passwordEncoder.matches(request.password(), user.getPasswordHash());

        // Uniform failure regardless of which check failed (no enumeration).
        if (!passwordMatches || user.getStatus() != UserStatus.ACTIVE) {
            throw new ApiException(401, "UNAUTHORIZED", "Invalid email or password");
        }
        return buildAuthResponse(user);
    }

    /**
     * Validates a presented token and returns the safe identity view.
     * The caller identity always originates from the verified token.
     */
    @Transactional(readOnly = true)
    public AuthResponse validate(AuthenticatedUser principal) {
        User user = userRepository.findById(principal.id())
                .filter(found -> found.getStatus() == UserStatus.ACTIVE)
                .orElseThrow(() -> new ApiException(401, "UNAUTHORIZED", "Invalid email or password"));
        return new AuthResponse(null, null, 0,
                new AuthResponse.UserView(user.getId(), user.getEmail(), user.getDisplayName()));
    }

    /**
     * Stateless logout: the server holds no session to revoke; clients
     * discard the token. Kept as an authenticated endpoint so Flutter has a
     * stable API hook (AUTH-003).
     */
    public void logout() {
        // Intentionally stateless — documented behaviour for AUTH-003.
    }

    private AuthResponse buildAuthResponse(User user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getDisplayName());
        return new AuthResponse(token, "Bearer", jwtService.getExpirationSeconds(),
                new AuthResponse.UserView(user.getId(), user.getEmail(), user.getDisplayName()));
    }
}
