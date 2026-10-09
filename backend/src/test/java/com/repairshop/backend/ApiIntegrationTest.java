package com.repairshop.backend;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.repairshop.backend.model.Shop;
import com.repairshop.backend.service.PasswordResetNotifier;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ApiIntegrationTest {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ObjectMapper json;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private CapturingResetNotifier resetNotifier;

    // Captures reset codes instead of emailing them
    static class CapturingResetNotifier extends PasswordResetNotifier {
        final Map<String, String> codesByEmail = new ConcurrentHashMap<>();

        CapturingResetNotifier() {
            super(null, "test@example.com", 15, "");
        }

        @Override
        public void sendResetCode(Shop shop, String code) {
            codesByEmail.put(shop.getEmail(), code);
        }
    }

    @TestConfiguration
    static class TestBeans {
        @Bean
        @Primary
        CapturingResetNotifier capturingResetNotifier() {
            return new CapturingResetNotifier();
        }
    }

    // ---------------------------------------------------------------- auth

    @Test
    void signupAcceptsUsernameFieldSentByMobileAppAndReturnsIt() throws Exception {
        String email = uniqueEmail();
        JsonNode body = signup(email);

        assertThat(body.at("/shop/username").asText()).startsWith("user");
        assertThat(body.at("/shop/mobileNumber").asText()).isEqualTo("9999999999");
        assertThat(body.at("/accessToken").asText()).isNotBlank();
        assertThat(body.at("/refreshToken").asText()).isNotBlank();
    }

    @Test
    void duplicateEmailIsConflict() throws Exception {
        String email = uniqueEmail();
        signup(email);
        perform(post("/api/v1/auth/signup"), null, signupBody(email)).andExpect(status().isConflict());
    }

    @Test
    void wrongPasswordIs401AndRepeatedFailuresAreThrottled() throws Exception {
        String email = uniqueEmail();
        signup(email);

        for (int i = 0; i < 5; i++) {
            perform(post("/api/v1/auth/login"), null, Map.of("email", email, "password", "wrong-password"))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.message").value("Invalid email or password"));
        }
        perform(post("/api/v1/auth/login"), null, Map.of("email", email, "password", "password123"))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void loginIsCaseInsensitiveOnEmail() throws Exception {
        String email = uniqueEmail();
        signup(email);
        perform(post("/api/v1/auth/login"), null, Map.of("email", email.toUpperCase(), "password", "password123"))
                .andExpect(status().isOk());
    }

    @Test
    void missingOrInvalidAccessTokenIs401() throws Exception {
        mvc.perform(get("/api/v1/orders")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/orders").header("Authorization", "Bearer not-a-jwt"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void loggingInOnSecondDeviceKeepsFirstDeviceSignedIn() throws Exception {
        String email = uniqueEmail();
        String firstDeviceRefresh = signup(email).at("/refreshToken").asText();

        perform(post("/api/v1/auth/login"), null, Map.of("email", email, "password", "password123"))
                .andExpect(status().isOk());

        perform(post("/api/v1/auth/refresh"), null, Map.of("refreshToken", firstDeviceRefresh))
                .andExpect(status().isOk());
    }

    @Test
    void refreshRotatesTokenAndReplayRevokesAllSessions() throws Exception {
        String original = signup(uniqueEmail()).at("/refreshToken").asText();

        JsonNode rotated = read(perform(post("/api/v1/auth/refresh"), null, Map.of("refreshToken", original))
                .andExpect(status().isOk()));
        String next = rotated.at("/refreshToken").asText();
        assertThat(next).isNotEqualTo(original);

        // Replaying the rotated-out token looks like theft -> everything is revoked
        perform(post("/api/v1/auth/refresh"), null, Map.of("refreshToken", original))
                .andExpect(status().isUnauthorized());
        perform(post("/api/v1/auth/refresh"), null, Map.of("refreshToken", next))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutRevokesRefreshToken() throws Exception {
        String refresh = signup(uniqueEmail()).at("/refreshToken").asText();
        perform(post("/api/v1/auth/logout"), null, Map.of("refreshToken", refresh)).andExpect(status().isNoContent());
        perform(post("/api/v1/auth/refresh"), null, Map.of("refreshToken", refresh)).andExpect(status().isUnauthorized());
    }

    @Test
    void forgotAndResetPasswordWithEmailedCode() throws Exception {
        String email = uniqueEmail();
        signup(email);

        perform(post("/api/v1/auth/forgot-password"), null, Map.of("email", email)).andExpect(status().isOk());
        String code = resetNotifier.codesByEmail.get(email);
        assertThat(code).matches("\\d{6}");

        String wrongCode = code.equals("000000") ? "111111" : "000000";
        perform(post("/api/v1/auth/reset-password"), null,
                Map.of("email", email, "code", wrongCode, "newPassword", "new-password-1"))
                .andExpect(status().isBadRequest());

        perform(post("/api/v1/auth/reset-password"), null,
                Map.of("email", email, "code", code, "newPassword", "new-password-1"))
                .andExpect(status().isOk());

        perform(post("/api/v1/auth/login"), null, Map.of("email", email, "password", "password123"))
                .andExpect(status().isUnauthorized());
        perform(post("/api/v1/auth/login"), null, Map.of("email", email, "password", "new-password-1"))
                .andExpect(status().isOk());

        // Code is single-use
        perform(post("/api/v1/auth/reset-password"), null,
                Map.of("email", email, "code", code, "newPassword", "another-pass-2"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void forgotPasswordForUnknownEmailLooksTheSame() throws Exception {
        perform(post("/api/v1/auth/forgot-password"), null, Map.of("email", uniqueEmail())).andExpect(status().isOk());
    }

    // ---------------------------------------------------------------- orders

    @Test
    void ordersArePagedAndIsolatedPerShop() throws Exception {
        String tokenA = signup(uniqueEmail()).at("/accessToken").asText();
        String tokenB = signup(uniqueEmail()).at("/accessToken").asText();

        String orderId = null;
        for (int i = 0; i < 3; i++) {
            JsonNode created = read(perform(post("/api/v1/orders"), tokenA, order(null, "PENDING", Instant.now()))
                    .andExpect(status().isCreated()));
            orderId = created.at("/id").asText();
        }

        perform(get("/api/v1/orders?size=2"), tokenA, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.totalElements").value(3));

        perform(get("/api/v1/orders/" + orderId), tokenB, null).andExpect(status().isNotFound());
        perform(get("/api/v1/orders"), tokenB, null).andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void invalidStatusIsRejected() throws Exception {
        String token = signup(uniqueEmail()).at("/accessToken").asText();
        Map<String, Object> body = order(null, "PENDING", Instant.now());
        body.put("status", "FIXED");
        perform(post("/api/v1/orders"), token, body).andExpect(status().isBadRequest());
    }

    @Test
    void devicePasscodeIsEncryptedAtRestAndClearedOnDelivery() throws Exception {
        String token = signup(uniqueEmail()).at("/accessToken").asText();
        Map<String, Object> body = order(null, "PENDING", Instant.now());
        body.put("devicePassword", "1234");
        body.put("devicePattern", "1-2-3-6-9");

        JsonNode created = read(perform(post("/api/v1/orders"), token, body).andExpect(status().isCreated()));
        String id = created.at("/id").asText();
        assertThat(created.at("/devicePassword").asText()).isEqualTo("1234");

        String stored = jdbc.queryForObject("SELECT device_password FROM repair_orders WHERE id = ?", String.class, id);
        assertThat(stored).startsWith("enc:v1:").doesNotContain("1234");

        body.put("status", "DELIVERED");
        JsonNode delivered = read(perform(put("/api/v1/orders/" + id), token, body).andExpect(status().isOk()));
        assertThat(delivered.at("/devicePassword").isNull()).isTrue();
        assertThat(delivered.at("/devicePattern").isNull()).isTrue();
    }

    // ---------------------------------------------------------------- sync

    @Test
    void deletionOnOneDeviceReachesTheOtherDevice() throws Exception {
        String email = uniqueEmail();
        String phone1 = signup(email).at("/accessToken").asText();
        String phone2 = login(email).at("/accessToken").asText();

        String id = UUID.randomUUID().toString();
        JsonNode first = sync(phone1, null, List.of(order(id, "PENDING", Instant.now())), List.of());
        Instant phone2Cursor = Instant.parse(sync(phone2, null, List.of(), List.of()).at("/serverSyncTime").asText());

        sync(phone1, Instant.parse(first.at("/serverSyncTime").asText()), List.of(), List.of(id));

        JsonNode pulled = sync(phone2, phone2Cursor, List.of(), List.of());
        JsonNode tombstone = findOrder(pulled, id);
        assertThat(tombstone).isNotNull();
        assertThat(tombstone.at("/deleted").asBoolean()).isTrue();

        // and it no longer shows up in a fresh full sync
        assertThat(findOrder(sync(phone2, null, List.of(), List.of()), id)).isNull();
    }

    @Test
    void olderEditLosesAndClientReceivesWinningVersion() throws Exception {
        String token = signup(uniqueEmail()).at("/accessToken").asText();
        String id = UUID.randomUUID().toString();
        Instant t0 = Instant.now().truncatedTo(ChronoUnit.MILLIS);

        Map<String, Object> newer = order(id, "REPAIRED", t0.plusSeconds(60));
        JsonNode first = sync(token, null, List.of(newer), List.of());
        Instant cursor = Instant.parse(first.at("/serverSyncTime").asText());

        Map<String, Object> older = order(id, "CANCELLED", t0);
        JsonNode response = sync(token, cursor, List.of(older), List.of());

        assertThat(findOrder(response, id).at("/status").asText()).isEqualTo("REPAIRED");
    }

    @Test
    void clientClockFarInTheFutureIsClamped() throws Exception {
        String token = signup(uniqueEmail()).at("/accessToken").asText();
        String id = UUID.randomUUID().toString();

        JsonNode response = sync(token, null, List.of(order(id, "PENDING", Instant.now().plus(365, ChronoUnit.DAYS))), List.of());
        Instant stored = Instant.parse(findOrder(response, id).at("/updatedAt").asText());
        assertThat(stored).isBefore(Instant.now().plus(1, ChronoUnit.HOURS));
    }

    @Test
    void oneInvalidOrderDoesNotBlockTheRestOfTheSync() throws Exception {
        String token = signup(uniqueEmail()).at("/accessToken").asText();
        String goodId = UUID.randomUUID().toString();
        Map<String, Object> bad = order(UUID.randomUUID().toString(), "PENDING", Instant.now());
        bad.put("customerName", "");

        JsonNode response = sync(token, null, List.of(bad, order(goodId, "PENDING", Instant.now())), List.of());
        assertThat(findOrder(response, goodId)).isNotNull();
    }

    // ---------------------------------------------------------------- helpers

    private static String uniqueEmail() {
        return "owner-" + UUID.randomUUID() + "@example.com";
    }

    private static Map<String, Object> signupBody(String email) {
        Map<String, Object> body = new HashMap<>();
        body.put("shopType", "Mobile Repair");
        body.put("shopName", "Test Shop");
        body.put("ownerName", "Test Owner");
        body.put("username", "user" + UUID.randomUUID().toString().substring(0, 8));
        body.put("mobileNumber", "9999999999");
        body.put("countryCode", "+91");
        body.put("email", email);
        body.put("password", "password123");
        body.put("currencySymbol", "₹");
        return body;
    }

    private JsonNode signup(String email) throws Exception {
        return read(perform(post("/api/v1/auth/signup"), null, signupBody(email)).andExpect(status().isOk()));
    }

    private JsonNode login(String email) throws Exception {
        return read(perform(post("/api/v1/auth/login"), null, Map.of("email", email, "password", "password123"))
                .andExpect(status().isOk()));
    }

    private static Map<String, Object> order(String id, String status, Instant updatedAt) {
        Map<String, Object> body = new HashMap<>();
        if (id != null) {
            body.put("id", id);
        }
        body.put("status", status);
        body.put("repairDate", "2026-10-07");
        body.put("repairTime", "10:30:00");
        body.put("customerName", "Ravi Kumar");
        body.put("customerNumber", "9876543210");
        body.put("deviceProblem", "Broken screen");
        body.put("estimatePrice", 1500.50);
        body.put("paidPrice", 500);
        body.put("createdAt", updatedAt.toString());
        body.put("updatedAt", updatedAt.toString());
        return body;
    }

    private JsonNode sync(String token, Instant lastSyncTime, List<Map<String, Object>> orders, List<String> deletedIds) throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("lastSyncTime", lastSyncTime == null ? null : lastSyncTime.toString());
        body.put("localOrders", orders);
        body.put("deletedOrderIds", deletedIds);
        return read(perform(post("/api/v1/orders/sync"), token, body).andExpect(status().isOk()));
    }

    private static JsonNode findOrder(JsonNode syncResponse, String id) {
        for (JsonNode order : syncResponse.at("/serverOrders")) {
            if (order.at("/id").asText().equals(id)) {
                return order;
            }
        }
        return null;
    }

    private ResultActions perform(MockHttpServletRequestBuilder request, String token, Object body) throws Exception {
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        if (body != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(body));
        }
        return mvc.perform(request);
    }

    private JsonNode read(ResultActions result) throws Exception {
        return json.readTree(result.andReturn().getResponse().getContentAsString());
    }
}
