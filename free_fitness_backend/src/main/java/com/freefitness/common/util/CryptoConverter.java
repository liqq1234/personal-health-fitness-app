package com.freefitness.common.util;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * JPA 属性转换器：用于 Double 类型的敏感字段（如体重、BMI）自动加解密
 * 实体中为 Double，数据库中为 AES 加密后的 String
 */
@Component
@Converter
public class CryptoConverter implements AttributeConverter<Double, String> {

    private static String secretKey;

    @Value("${aes.secret-key}")
    public void setSecretKey(String key) {
        secretKey = key;
    }

    @Override
    public String convertToDatabaseColumn(Double attribute) {
        if (attribute == null) return null;
        return AesUtil.encryptDouble(attribute, secretKey);
    }

    @Override
    public Double convertToEntityAttribute(String dbData) {
        if (dbData == null) return null;
        try {
            return AesUtil.decryptDouble(dbData, secretKey);
        } catch (Exception e) {
            // 如果已经是明文（如旧数据），直接尝试解析
            try {
                return Double.parseDouble(dbData);
            } catch (NumberFormatException nfe) {
                return null;
            }
        }
    }
}
