package com.freefitness.system.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 全量数据备份记录（对应 ff_backup 表）
 * content 字段存储整个备份的 JSON 字符串
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_backup")
public class Backup {

    @Id
    @Column(name = "backup_id", length = 36)
    private String backupId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "backup_version", length = 16)
    private String backupVersion;

    @Column(name = "size_kb")
    private Integer sizeKb;

    @Column(name = "data", nullable = false, columnDefinition = "LONGTEXT")
    private String data;   // 全量嵌套 JSON

    @Column(name = "saved_at", nullable = false, length = 30)
    private String savedAt;
}
