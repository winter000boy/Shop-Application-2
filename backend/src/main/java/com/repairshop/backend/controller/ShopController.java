package com.repairshop.backend.controller;

import com.repairshop.backend.dto.AuthResponse;
import com.repairshop.backend.dto.ShopUpdateDto;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.service.ShopService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/shop")
public class ShopController {

    private final ShopService shopService;

    public ShopController(ShopService shopService) {
        this.shopService = shopService;
    }

    @GetMapping
    public ResponseEntity<AuthResponse.ShopDto> getShopProfile() {
        Shop shop = shopService.getCurrentShop();
        return ResponseEntity.ok(toDto(shop));
    }

    @PutMapping
    public ResponseEntity<AuthResponse.ShopDto> updateShopProfile(@Valid @RequestBody ShopUpdateDto dto) {
        Shop updatedShop = shopService.updateShopDetails(dto);
        return ResponseEntity.ok(toDto(updatedShop));
    }

    private AuthResponse.ShopDto toDto(Shop shop) {
        return new AuthResponse.ShopDto(
                shop.getId(),
                shop.getShopName(),
                shop.getShopType(),
                shop.getOwnerName(),
                shop.getCommunityUsername(),
                shop.getEmail(),
                shop.getCurrencySymbol(),
                shop.getLogoUrl()
        );
    }
}
