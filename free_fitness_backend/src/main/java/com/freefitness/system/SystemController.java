package com.freefitness.system;

import com.freefitness.common.Result;
import com.freefitness.system.entity.Backup;
import com.freefitness.system.entity.UserSettings;
import com.freefitness.system.repository.BackupRepository;
import com.freefitness.system.repository.UserSettingsRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * 系统模块接口：数据备份与恢复 / 用户偏好设置 / 附加功能 (建议、配置、版本)
 */
@Tag(name = "系统模块", description = "全量备份 / 偏好设置 / AI建议代理")
@RestController
@RequestMapping("/api/v1/system")
@RequiredArgsConstructor
public class SystemController {

    private final BackupRepository backupRepo;
    private final UserSettingsRepository settingsRepo;

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    // ──────── 6.1-6.4 全量数据备份 ────────

    @Operation(summary = "全量数据备份上传", 
               description = "接收前端全量导出的嵌套 JSON 快照，保存到云端。")
    @PostMapping("/backup/upload")
    @Transactional
    public Result<Map<String, Object>> uploadBackup(
            @AuthenticationPrincipal Long userId,
            @RequestBody String fullJson) {
        
        Backup b = new Backup();
        b.setBackupId(UUID.randomUUID().toString());
        b.setUserId(userId);
        b.setBackupVersion("1.0"); // 默认版本
        b.setSavedAt(LocalDateTime.now().format(DT));
        b.setSizeKb(fullJson.length() / 1024);
        b.setData(fullJson);
        
        Backup saved = backupRepo.save(b);
        return Result.success(Map.of(
            "backupId", saved.getBackupId(),
            "savedAt", saved.getSavedAt(),
            "sizeKb", saved.getSizeKb()
        ));
    }

    @Operation(summary = "查询备份记录列表")
    @GetMapping("/backup/list")
    public Result<List<Backup>> listBackups(@AuthenticationPrincipal Long userId) {
        // 出库前清空 data 字段以减少传输开销，如果用户只要列表
        List<Backup> list = backupRepo.findByUserIdOrderBySavedAtDesc(userId);
        list.forEach(b -> b.setData(null));
        return Result.success(list);
    }

    @Operation(summary = "下载备份全量数据")
    @GetMapping("/backup/{backupId}")
    public Result<String> getBackup(@AuthenticationPrincipal Long userId, @PathVariable String backupId) {
        Backup b = backupRepo.findById(backupId)
                .orElseThrow(() -> new IllegalArgumentException("备份记录不存在"));
        if (!b.getUserId().equals(userId)) {
            throw new IllegalArgumentException("无权下载他人备份");
        }
        return Result.success(b.getData());
    }

    @Operation(summary = "删除备份记录")
    @DeleteMapping("/backup/{backupId}")
    @Transactional
    public Result<Void> deleteBackup(@AuthenticationPrincipal Long userId, @PathVariable String backupId) {
        Backup b = backupRepo.findById(backupId)
                .orElseThrow(() -> new IllegalArgumentException("备份记录不存在"));
        if (!b.getUserId().equals(userId)) {
            throw new IllegalArgumentException("无权删除他人备份");
        }
        backupRepo.delete(b);
        return Result.success();
    }

    // ──────── 6.5 偏好设置同步 ────────

    @Operation(summary = "同步/拉取用户偏好设置")
    @GetMapping("/settings")
    public Result<UserSettings> getSettings(@AuthenticationPrincipal Long userId) {
        return Result.success(settingsRepo.findByUserId(userId)
                .orElse(new UserSettings()));
    }

    @Operation(summary = "更新用户偏好设置（主题、语言）")
    @PutMapping("/settings")
    @Transactional
    public Result<UserSettings> updateSettings(
            @AuthenticationPrincipal Long userId,
            @RequestBody UserSettings req) {
        
        UserSettings settings = settingsRepo.findByUserId(userId)
                .orElse(new UserSettings());
        settings.setUserId(userId);
        if (req.getTheme() != null) settings.setTheme(req.getTheme());
        if (req.getLanguage() != null) settings.setLanguage(req.getLanguage());
        settings.setGmtModified(LocalDateTime.now().format(DT));
        
        return Result.success(settingsRepo.save(settings));
    }

    // ──────── 附加：AI 建议与系统信息 ────────

    @Operation(summary = "获取 AI 健康建议（后端代理代理）")
    @GetMapping("/suggest")
    public Result<Map<String, String>> getAiSuggestion() {
        return Result.success(Map.of(
            "suggestion", "建议今天增加 20 分钟的有氧运动，并补充蛋白质。保持良好心态！",
            "timestamp", String.valueOf(System.currentTimeMillis())
        ));
    }

    @Operation(summary = "检查版本更新")
    @GetMapping("/version")
    public Result<Map<String, Object>> checkVersion() {
        return Result.success(Map.of(
            "latest_version", "1.0.1",
            "force_update", false,
            "update_url", "https://app.freefitness.com/download/latest.apk"
        ));
    }
}
