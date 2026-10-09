package com.repairshop.backend.exception;

// Thrown when a request conflicts with existing data -> 409
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
