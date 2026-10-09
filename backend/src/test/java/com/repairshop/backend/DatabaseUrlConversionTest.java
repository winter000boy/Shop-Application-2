package com.repairshop.backend;

import com.repairshop.backend.config.DatabaseUrlEnvironmentPostProcessor;
import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;
import org.springframework.mock.env.MockEnvironment;

import static org.assertj.core.api.Assertions.assertThat;

class DatabaseUrlConversionTest {

    private final DatabaseUrlEnvironmentPostProcessor processor = new DatabaseUrlEnvironmentPostProcessor();

    @Test
    void convertsPlatformStyleUrlWithoutPort() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("DATABASE_URL", "postgresql://fix_user:p%40ss@dpg-abc123-a/fixmanager");
        processor.postProcessEnvironment(env, new SpringApplication());

        assertThat(env.getProperty("spring.datasource.url")).isEqualTo("jdbc:postgresql://dpg-abc123-a:5432/fixmanager");
        assertThat(env.getProperty("spring.datasource.username")).isEqualTo("fix_user");
        assertThat(env.getProperty("spring.datasource.password")).isEqualTo("p@ss");
    }

    @Test
    void keepsPortAndQuery() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("DATABASE_URL", "postgres://u:p@db.example.com:6543/app?sslmode=require");
        processor.postProcessEnvironment(env, new SpringApplication());

        assertThat(env.getProperty("spring.datasource.url"))
                .isEqualTo("jdbc:postgresql://db.example.com:6543/app?sslmode=require");
    }

    @Test
    void leavesJdbcUrlsAlone() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("DATABASE_URL", "jdbc:postgresql://localhost:5432/repairshop");
        processor.postProcessEnvironment(env, new SpringApplication());

        assertThat(env.getPropertySources().contains("convertedDatabaseUrl")).isFalse();
    }
}
