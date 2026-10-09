package com.repairshop.backend.service;

import com.repairshop.backend.dto.AuthResponse;
import com.repairshop.backend.dto.LoginRequest;
import com.repairshop.backend.dto.ResetPasswordRequest;
import com.repairshop.backend.dto.SignupRequest;
import com.repairshop.backend.exception.ConflictException;
import com.repairshop.backend.exception.InvalidTokenException;
import com.repairshop.backend.exception.TooManyRequestsException;
import com.repairshop.backend.model.PasswordResetCode;
import com.repairshop.backend.model.RefreshToken;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.repository.PasswordResetCodeRepository;
import com.repairshop.backend.repository.RefreshTokenRepository;
import com.repairshop.backend.repository.ShopRepository;
import com.repairshop.backend.security.JwtService;
import com.repairshop.backend.security.LoginAttemptService;
import com.repairshop.backend.security.TokenHasher;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Locale;
import java.util.Optional;

@Service
public class AuthService {

    private static final int MAX_RESET_CODE_ATTEMPTS = 5;
    private static final Duration RESET_CODE_RESEND_INTERVAL = Duration.ofMinutes(1);
    private static final String INVALID_RESET_CODE = "Invalid or expired reset code";

    private final ShopRepository shopRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordResetCodeRepository passwordResetCodeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final LoginAttemptService loginAttemptService;
    private final PasswordResetNotifier passwordResetNotifier;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${app.jwt.refreshTokenExpirationMs}")
    private long refreshTokenDurationMs;

    @Value("${app.password-reset.code-expiration-minutes}")
    private long resetCodeExpirationMinutes;

    public AuthService(
            ShopRepository shopRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordResetCodeRepository passwordResetCodeRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            AuthenticationManager authenticationManager,
            LoginAttemptService loginAttemptService,
            PasswordResetNotifier passwordResetNotifier
    ) {
        this.shopRepository = shopRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordResetCodeRepository = passwordResetCodeRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
        this.loginAttemptService = loginAttemptService;
        this.passwordResetNotifier = passwordResetNotifier;
    }

    @Transactional
    public AuthResponse signup(SignupRequest request) {
        String email = normalizeEmail(request.getEmail());
        String username = request.getUsername().trim();

        if (shopRepository.existsByEmail(email)) {
            throw new ConflictException("Email address is already in use");
        }
        if (shopRepository.existsByUsername(username)) {
            throw new ConflictException("Username is already taken");
        }

        Shop shop = new Shop();
        shop.setShopName(request.getShopName());
        shop.setShopType(request.getShopType());
        shop.setGstNumber(request.getGstNumber());
        shop.setOwnerName(request.getOwnerName());
        shop.setCommunityUsername(username);
        shop.setMobileNumber(request.getMobileNumber());
        shop.setCountryCode(request.getCountryCode());
        shop.setAddress(request.getShopAddress());
        shop.setEmail(email);
        shop.setPassword(passwordEncoder.encode(request.getPassword()));
        shop.setCurrencySymbol(request.getCurrencySymbol());
        shop.setLogoUrl(request.getLogoUrl());

        Shop savedShop = shopRepository.save(shop);
        return issueTokens(savedShop);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (loginAttemptService.isBlocked(email)) {
            throw new TooManyRequestsException("Too many failed attempts. Please try again in a few minutes");
        }

        try {
            authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(email, request.getPassword()));
        } catch (BadCredentialsException e) {
            loginAttemptService.recordFailure(email);
            throw e;
        }
        loginAttemptService.recordSuccess(email);

        Shop shop = shopRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        // Each device keeps its own refresh token; only clean up dead ones
        refreshTokenRepository.deleteStaleTokens(shop, Instant.now());
        return issueTokens(shop);
    }

    // Exchanges a refresh token for a new access token AND a new refresh token (rotation)
    @Transactional(noRollbackFor = InvalidTokenException.class)
    public AuthResponse refreshToken(String rawRefreshToken) {
        RefreshToken token = refreshTokenRepository.findByTokenHash(TokenHasher.sha256(rawRefreshToken))
                .orElseThrow(() -> new InvalidTokenException("Session expired. Please sign in again"));
        Shop shop = token.getShop();

        if (token.isRevoked()) {
            // A rotated-out token was replayed: assume it leaked and sign the shop out everywhere
            refreshTokenRepository.deleteByShop(shop);
            throw new InvalidTokenException("Session expired. Please sign in again");
        }
        if (token.getExpiryDate().isBefore(Instant.now())) {
            refreshTokenRepository.delete(token);
            throw new InvalidTokenException("Session expired. Please sign in again");
        }

        token.setRevoked(true);
        return issueTokens(shop);
    }

    @Transactional
    public void logout(String rawRefreshToken) {
        refreshTokenRepository.findByTokenHash(TokenHasher.sha256(rawRefreshToken))
                .ifPresent(token -> token.setRevoked(true));
    }

    // Always succeeds from the caller's point of view so the endpoint can't be used to discover accounts
    @Transactional
    public void forgotPassword(String rawEmail) {
        Optional<Shop> shopOpt = shopRepository.findByEmail(normalizeEmail(rawEmail));
        if (shopOpt.isEmpty()) {
            return;
        }
        Shop shop = shopOpt.get();
        Instant now = Instant.now();

        Optional<PasswordResetCode> latest = passwordResetCodeRepository.findFirstByShopAndUsedFalseOrderByExpiresAtDesc(shop);
        Instant latestIssuedAt = latest.map(c -> c.getExpiresAt().minus(Duration.ofMinutes(resetCodeExpirationMinutes))).orElse(null);
        if (latestIssuedAt != null && latestIssuedAt.plus(RESET_CODE_RESEND_INTERVAL).isAfter(now)) {
            return; // a code was sent less than a minute ago; don't spam the inbox
        }

        passwordResetCodeRepository.deleteByShop(shop);
        String code = String.format("%06d", secureRandom.nextInt(1_000_000));

        PasswordResetCode resetCode = new PasswordResetCode();
        resetCode.setShop(shop);
        resetCode.setCodeHash(passwordEncoder.encode(code));
        resetCode.setExpiresAt(now.plus(Duration.ofMinutes(resetCodeExpirationMinutes)));
        passwordResetCodeRepository.save(resetCode);

        passwordResetNotifier.sendResetCode(shop, code);
    }

    // Failed attempts must be persisted even though the request fails, hence noRollbackFor
    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public void resetPassword(ResetPasswordRequest request) {
        Shop shop = shopRepository.findByEmail(normalizeEmail(request.getEmail()))
                .orElseThrow(() -> new IllegalArgumentException(INVALID_RESET_CODE));
        PasswordResetCode resetCode = passwordResetCodeRepository.findFirstByShopAndUsedFalseOrderByExpiresAtDesc(shop)
                .orElseThrow(() -> new IllegalArgumentException(INVALID_RESET_CODE));

        if (resetCode.getExpiresAt().isBefore(Instant.now()) || resetCode.getAttempts() >= MAX_RESET_CODE_ATTEMPTS) {
            throw new IllegalArgumentException(INVALID_RESET_CODE);
        }
        if (!passwordEncoder.matches(request.getCode(), resetCode.getCodeHash())) {
            resetCode.setAttempts(resetCode.getAttempts() + 1);
            throw new IllegalArgumentException(INVALID_RESET_CODE);
        }

        resetCode.setUsed(true);
        shop.setPassword(passwordEncoder.encode(request.getNewPassword()));
        shopRepository.save(shop);
        // Sign out every device that used the old password
        refreshTokenRepository.deleteByShop(shop);
        loginAttemptService.recordSuccess(shop.getEmail());
    }

    private AuthResponse issueTokens(Shop shop) {
        String rawRefreshToken = newOpaqueToken();

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setShop(shop);
        refreshToken.setExpiryDate(Instant.now().plusMillis(refreshTokenDurationMs));
        refreshToken.setTokenHash(TokenHasher.sha256(rawRefreshToken));
        refreshToken.setRevoked(false);
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(
                jwtService.generateToken(shop),
                rawRefreshToken,
                jwtService.getExpirationTime(),
                AuthResponse.ShopDto.from(shop)
        );
    }

    private String newOpaqueToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String normalizeEmail(String email) {
        return email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }
}
