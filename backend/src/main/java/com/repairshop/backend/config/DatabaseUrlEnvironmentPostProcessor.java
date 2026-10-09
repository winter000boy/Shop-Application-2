package com.repairshop.backend.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * Hosting platforms (Render, Railway, Heroku...) hand out the database as
 * DATABASE_URL=postgresql://user:password@host:port/dbname, but JDBC needs jdbc:postgresql://host:port/dbname
 * with the credentials passed separately. This converts the former into Spring datasource properties.
 * A DATABASE_URL that already starts with "jdbc:" is left alone.
 */
public class DatabaseUrlEnvironmentPostProcessor implements EnvironmentPostProcessor {

    static final String PROPERTY_SOURCE_NAME = "convertedDatabaseUrl";

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String databaseUrl = environment.getProperty("DATABASE_URL");
        if (databaseUrl == null || !(databaseUrl.startsWith("postgres://") || databaseUrl.startsWith("postgresql://"))) {
            return;
        }
        environment.getPropertySources().addFirst(new MapPropertySource(PROPERTY_SOURCE_NAME, convert(databaseUrl)));
    }

    static Map<String, Object> convert(String databaseUrl) {
        URI uri = URI.create(databaseUrl);
        int port = uri.getPort() == -1 ? 5432 : uri.getPort();
        String jdbcUrl = "jdbc:postgresql://" + uri.getHost() + ":" + port + uri.getRawPath()
                + (uri.getRawQuery() != null ? "?" + uri.getRawQuery() : "");

        Map<String, Object> properties = new HashMap<>();
        properties.put("spring.datasource.url", jdbcUrl);

        String userInfo = uri.getRawUserInfo();
        if (userInfo != null) {
            int colon = userInfo.indexOf(':');
            String username = colon >= 0 ? userInfo.substring(0, colon) : userInfo;
            properties.put("spring.datasource.username", URLDecoder.decode(username, StandardCharsets.UTF_8));
            if (colon >= 0) {
                properties.put("spring.datasource.password",
                        URLDecoder.decode(userInfo.substring(colon + 1), StandardCharsets.UTF_8));
            }
        }
        return properties;
    }
}
