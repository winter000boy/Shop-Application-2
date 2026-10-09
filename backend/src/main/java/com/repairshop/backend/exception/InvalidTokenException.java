package com.repairshop.backend.exception;

// Thrown when a refresh token or reset code is invalid, expired or revoked -> 401
public class InvalidTokenException extends RuntimeException {

    public InvalidTokenException(String message) {
        super(message);
    }
}
