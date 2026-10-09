package com.repairshop.backend.service;

import com.repairshop.backend.model.Shop;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Delivers password-reset codes. Uses SMTP when spring.mail.host is configured; otherwise the code is
 * written to the server log (fine for local development, configure mail for real deployments).
 */
@Component
public class PasswordResetNotifier {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetNotifier.class);

    private final ObjectProvider<JavaMailSender> mailSender;
    private final String mailFrom;
    private final long expirationMinutes;
    private final boolean mailConfigured;

    public PasswordResetNotifier(
            ObjectProvider<JavaMailSender> mailSender,
            @Value("${app.password-reset.mail-from}") String mailFrom,
            @Value("${app.password-reset.code-expiration-minutes}") long expirationMinutes,
            @Value("${spring.mail.host:}") String mailHost
    ) {
        this.mailSender = mailSender;
        this.mailFrom = mailFrom;
        this.expirationMinutes = expirationMinutes;
        // A blank SPRING_MAIL_HOST (e.g. an empty dashboard field) still creates a mail sender that can't send
        this.mailConfigured = mailHost != null && !mailHost.isBlank();
    }

    public void sendResetCode(Shop shop, String code) {
        JavaMailSender sender = mailConfigured ? mailSender.getIfAvailable() : null;
        if (sender == null) {
            log.warn("Mail is not configured. Password reset code for {}: {}", shop.getEmail(), code);
            return;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(mailFrom);
        message.setTo(shop.getEmail());
        message.setSubject("Your FixManager password reset code");
        message.setText("Hello " + shop.getOwnerName() + ",\n\n"
                + "Your password reset code is: " + code + "\n"
                + "It expires in " + expirationMinutes + " minutes.\n\n"
                + "If you did not request this, you can ignore this email.");
        try {
            sender.send(message);
        } catch (MailException e) {
            log.error("Failed to send password reset email to {}", shop.getEmail(), e);
        }
    }
}
