package com.gamelearn;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;

/**
 * Backend entry point. The default-user auto-configuration is excluded
 * because Phase 0 has no authentication by design; Phase 2 introduces real
 * authentication explicitly.
 */
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
public class GameLearnApplication {

    public static void main(String[] args) {
        SpringApplication.run(GameLearnApplication.class, args);
    }
}
