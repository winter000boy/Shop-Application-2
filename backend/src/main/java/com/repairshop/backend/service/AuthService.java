package com.repairshop.backend.service;

import com.repairshop.backend.dto.AuthResponse;
import com.repairshop.backend.dto.LoginRequest;
import com.repairshop.backend.dto.RefreshTokenRequest;
import com.repairshop.backend.dto.SignupRequest;
import com.repairshop.backend.model.RefreshToken;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.repository.RefreshTokenRepository;
import com.repairshop.backend.repository.ShopRepository;
import com.repairshop.backend.security.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {

    private final ShopRepository shopRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Value("${app.jwt.refreshTokenExpirationMs}")
    private long refreshTokenDurationMs;

    public AuthService(
            ShopRepository shopRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            AuthenticationManager authenticationManager
    ) {
        this.shopRepository = shopRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
    }

    @Transactional
    public AuthResponse signup(SignupRequest request) {
        if (shopRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email address is already in use");
        }
        if (shopRepository.existsByUsername(request.getCommunityUsername())) {
            throw new IllegalArgumentException("Community username is already taken");
        }

        Shop shop = new Shop();
        shop.setShopName(request.getShopName());
        shop.setShopType(request.getShopType());
        shop.setGstNumber(request.getGstNumber());
        shop.setOwnerName(request.getOwnerName());
        shop.setCommunityUsername(request.getCommunityUsername());
        shop.setMobileNumber(request.getMobileNumber());
        shop.setCountryCode(request.getCountryCode());
        shop.setAddress(request.getShopAddress());
        shop.setEmail(request.getEmail());
        shop.setPassword(passwordEncoder.encode(request.getPassword()));
        shop.setCurrencySymbol(request.getCurrencySymbol());
        shop.setLogoUrl(request.getLogoUrl());

        Shop savedShop = shopRepository.save(shop);

        String jwtToken = jwtService.generateToken(savedShop);
        RefreshToken refreshToken = createRefreshToken(savedShop);

        return createAuthResponse(jwtToken, refreshToken, savedShop);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        Shop shop = shopRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        String jwtToken = jwtService.generateToken(shop);
        // Revoke existing refresh tokens and issue a new one
        refreshTokenRepository.deleteByShop(shop);
        RefreshToken refreshToken = createRefreshToken(shop);

        return createAuthResponse(jwtToken, refreshToken, shop);
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String requestRefreshToken = request.getRefreshToken();

        return refreshTokenRepository.findByToken(requestRefreshToken)
                .map(this::verifyExpiration)
                .map(token -> {
                    if (token.isRevoked()) {
                        throw new IllegalArgumentException("Refresh token has been revoked");
                    }
                    Shop shop = token.getShop();
                    String jwtToken = jwtService.generateToken(shop);
                    return createAuthResponse(jwtToken, token, shop);
                })
                .orElseThrow(() -> new IllegalArgumentException("Refresh token was not found in database"));
    }

    public void forgotPassword(String email) {
        Optional<Shop> shopOpt = shopRepository.findByEmail(email);
        if (shopOpt.isPresent()) {
            // In a production environment, this would send a reset email or OTP.
            // For Phase 1, we stub this by logging it.
            System.out.println("Password reset requested for email: " + email);
        }
    }

    private RefreshToken createRefreshToken(Shop shop) {
        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setShop(shop);
        refreshToken.setExpiryDate(Instant.now().plusMillis(refreshTokenDurationMs));
        refreshToken.setToken(UUID.randomUUID().toString());
        refreshToken.setRevoked(false);

        return refreshTokenRepository.save(refreshToken);
    }

    private RefreshToken verifyExpiration(RefreshToken token) {
        if (token.getExpiryDate().compareTo(Instant.now()) < 0) {
            refreshTokenRepository.delete(token);
            throw new IllegalArgumentException("Refresh token has expired. Please sign in again");
        }
        return token;
    }

    private AuthResponse createAuthResponse(String jwtToken, RefreshToken refreshToken, Shop shop) {
        AuthResponse.ShopDto shopDto = new AuthResponse.ShopDto(
                shop.getId(),
                shop.getShopName(),
                shop.getShopType(),
                shop.getOwnerName(),
                shop.getCommunityUsername(),
                shop.getEmail(),
                shop.getCurrencySymbol(),
                shop.getLogoUrl()
        );

        return new AuthResponse(
                jwtToken,
                refreshToken.getToken(),
                jwtService.getExpirationTime(),
                shopDto
        );
    }
}
