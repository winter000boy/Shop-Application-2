package com.repairshop.backend.security;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.stereotype.Component;

@Component
@Converter
public class EncryptedStringConverter implements AttributeConverter<String, String> {

    private final SecretCipher secretCipher;

    public EncryptedStringConverter(SecretCipher secretCipher) {
        this.secretCipher = secretCipher;
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        return secretCipher.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        return secretCipher.decrypt(dbData);
    }
}
