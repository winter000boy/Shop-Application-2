package com.repairshop.backend.service;

import com.repairshop.backend.dto.ShopUpdateDto;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.repository.ShopRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ShopService {

    private final ShopRepository shopRepository;

    public ShopService(ShopRepository shopRepository) {
        this.shopRepository = shopRepository;
    }

    public Shop getCurrentShop() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        // JwtAuthenticationFilter already loaded the Shop as the principal; avoid a second query per request
        if (authentication != null && authentication.getPrincipal() instanceof Shop shop) {
            return shop;
        }
        String email = authentication != null ? authentication.getName() : null;
        return shopRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Current authenticated shop owner not found"));
    }

    @Transactional
    public Shop updateShopDetails(ShopUpdateDto dto) {
        Shop currentShop = shopRepository.findById(getCurrentShop().getId())
                .orElseThrow(() -> new UsernameNotFoundException("Current authenticated shop owner not found"));
        currentShop.setShopName(dto.getShopName());
        currentShop.setShopType(dto.getShopType());
        currentShop.setOwnerName(dto.getOwnerName());
        currentShop.setMobileNumber(dto.getMobileNumber());
        currentShop.setCountryCode(dto.getCountryCode());
        currentShop.setAddress(dto.getShopAddress());
        currentShop.setCurrencySymbol(dto.getCurrencySymbol());
        currentShop.setLogoUrl(dto.getLogoUrl());
        currentShop.setGstNumber(dto.getGstNumber());

        return shopRepository.save(currentShop);
    }
}
