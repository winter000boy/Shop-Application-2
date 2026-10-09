package com.repairshop.backend.exception;

// Thrown when a client is temporarily throttled -> 429
public class TooManyRequestsException extends RuntimeException {

    public TooManyRequestsException(String message) {
        super(message);
    }
}
