package com.repairshop.backend.dto;

import com.repairshop.backend.model.Shop;

import java.util.UUID;

public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private long expiresInMs;
    private ShopDto shop;

    public AuthResponse(String accessToken, String refreshToken, long expiresInMs, ShopDto shop) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresInMs = expiresInMs;
        this.shop = shop;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public long getExpiresInMs() {
        return expiresInMs;
    }

    public void setExpiresInMs(long expiresInMs) {
        this.expiresInMs = expiresInMs;
    }

    public ShopDto getShop() {
        return shop;
    }

    public void setShop(ShopDto shop) {
        this.shop = shop;
    }

    public static class ShopDto {
        private UUID id;
        private String shopName;
        private String shopType;
        private String gstNumber;
        private String ownerName;
        private String username;
        private String email;
        private String mobileNumber;
        private String countryCode;
        private String address;
        private String currencySymbol;
        private String logoUrl;

        public ShopDto() {}

        public static ShopDto from(Shop shop) {
            ShopDto dto = new ShopDto();
            dto.id = shop.getId();
            dto.shopName = shop.getShopName();
            dto.shopType = shop.getShopType();
            dto.gstNumber = shop.getGstNumber();
            dto.ownerName = shop.getOwnerName();
            dto.username = shop.getCommunityUsername();
            dto.email = shop.getEmail();
            dto.mobileNumber = shop.getMobileNumber();
            dto.countryCode = shop.getCountryCode();
            dto.address = shop.getAddress();
            dto.currencySymbol = shop.getCurrencySymbol();
            dto.logoUrl = shop.getLogoUrl();
            return dto;
        }

        public UUID getId() {
            return id;
        }

        public void setId(UUID id) {
            this.id = id;
        }

        public String getShopName() {
            return shopName;
        }

        public void setShopName(String shopName) {
            this.shopName = shopName;
        }

        public String getShopType() {
            return shopType;
        }

        public void setShopType(String shopType) {
            this.shopType = shopType;
        }

        public String getGstNumber() {
            return gstNumber;
        }

        public void setGstNumber(String gstNumber) {
            this.gstNumber = gstNumber;
        }

        public String getOwnerName() {
            return ownerName;
        }

        public void setOwnerName(String ownerName) {
            this.ownerName = ownerName;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getMobileNumber() {
            return mobileNumber;
        }

        public void setMobileNumber(String mobileNumber) {
            this.mobileNumber = mobileNumber;
        }

        public String getCountryCode() {
            return countryCode;
        }

        public void setCountryCode(String countryCode) {
            this.countryCode = countryCode;
        }

        public String getAddress() {
            return address;
        }

        public void setAddress(String address) {
            this.address = address;
        }

        public String getCurrencySymbol() {
            return currencySymbol;
        }

        public void setCurrencySymbol(String currencySymbol) {
            this.currencySymbol = currencySymbol;
        }

        public String getLogoUrl() {
            return logoUrl;
        }

        public void setLogoUrl(String logoUrl) {
            this.logoUrl = logoUrl;
        }
    }
}
