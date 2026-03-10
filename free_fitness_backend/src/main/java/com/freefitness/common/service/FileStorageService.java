package com.freefitness.common.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

/**
 * 统一文件存储服务（本地磁盘实现）
 */
@Slf4j
@Service
public class FileStorageService {

    /**
     * 保存文件到指定目录
     * @param file 附件
     * @param storageDir 物理存储根目录
     * @param urlPrefix URL 前缀（如 /uploads/avatars/）
     * @return 返回可访问的相对 URL
     */
    public String storeFile(MultipartFile file, String storageDir, String urlPrefix) throws IOException {
        File dir = new File(storageDir);
        if (!dir.exists()) {
            boolean created = dir.mkdirs();
            log.info("创建存储目录: {}, 结果: {}", storageDir, created);
        }

        String originalFilename = file.getOriginalFilename();
        String ext = getExtension(originalFilename);
        String filename = UUID.randomUUID().toString().substring(0, 12) + "." + ext;
        
        File dest = new File(dir, filename);
        file.transferTo(dest);
        
        return urlPrefix.endsWith("/") ? urlPrefix + filename : urlPrefix + "/" + filename;
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "jpg";
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }
}
