package com.repairshop.backend.service;

import com.repairshop.backend.dto.ShopUpdateDto;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.repository.ShopRepository;
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
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return shopRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Current authenticated shop owner not found"));
    }

    @Transactional
    public Shop updateShopDetails(ShopUpdateDto dto) {
        Shop currentShop = getCurrentShop();
        currentShop.setShopName(dto.getShopName());
        currentShop.setShopType(dto.getShopType());
        currentShop.setOwnerName(dto.getOwnerName());
        currentShop.setMobileNumber(dto.getMobileNumber());
        currentShop.setCountryCode(dto.getCountryCode());
        currentShop.setAddress(dto.getShopAddress());
        currentShop.setCurrencySymbol(dto.getCurrencySymbol());
        currentShop.setLogoUrl(dto.getLogoUrl());

        return shopRepository.save(currentShop);
    }
}
