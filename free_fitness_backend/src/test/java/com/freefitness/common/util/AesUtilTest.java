package com.freefitness.common.util;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class AesUtilTest {

    private static final String SECRET_KEY = "12345678901234567890123456789012"; // 32 chars

    @Test
    void testEncryptionDecryption() {
        String plain = "hello free fitness";
        String cipher = AesUtil.encrypt(plain, SECRET_KEY);
        String decrypted = AesUtil.decrypt(cipher, SECRET_KEY);

        Assertions.assertNotEquals(plain, cipher);
        Assertions.assertEquals(plain, decrypted);
    }

    @Test
    void testDoubleEncryption() {
        Double val = 75.5;
        String cipher = AesUtil.encryptDouble(val, SECRET_KEY);
        Double decrypted = AesUtil.decryptDouble(cipher, SECRET_KEY);

        Assertions.assertEquals(val, decrypted);
    }
}
