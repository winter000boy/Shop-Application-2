package com.repairshop.backend.security;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Throttles password guessing: after MAX_FAILURES failed logins for an email, further attempts are
 * rejected until the lockout window has passed. In-memory, so it is per server instance.
 */
@Service
public class LoginAttemptService {

    static final int MAX_FAILURES = 5;
    static final Duration LOCKOUT = Duration.ofMinutes(15);

    private record Attempts(int failures, Instant firstFailure) {
    }

    private final Map<String, Attempts> attempts = new ConcurrentHashMap<>();

    public boolean isBlocked(String email) {
        Attempts entry = attempts.get(email);
        if (entry == null) {
            return false;
        }
        if (entry.firstFailure().plus(LOCKOUT).isBefore(Instant.now())) {
            attempts.remove(email);
            return false;
        }
        return entry.failures() >= MAX_FAILURES;
    }

    public void recordFailure(String email) {
        Instant now = Instant.now();
        attempts.merge(email, new Attempts(1, now), (old, ignored) ->
                old.firstFailure().plus(LOCKOUT).isBefore(now)
                        ? new Attempts(1, now)
                        : new Attempts(old.failures() + 1, old.firstFailure()));
    }

    public void recordSuccess(String email) {
        attempts.remove(email);
    }
}
