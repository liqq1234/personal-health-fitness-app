package com.freefitness.diary;

import com.freefitness.common.Result;
import com.freefitness.diary.entity.Diary;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * 日记接口
 */
@Tag(name = "日记", description = "日记 CRUD / 月度日历 / 多条件搜索 / 图片上传")
@RestController
@RequestMapping("/api/v1/diary")
@RequiredArgsConstructor
public class DiaryController {

    private final DiaryService diaryService;

    // ──────── 5.2 日记 CRUD ────────

    @Operation(summary = "分页查询日记列表（按日期倒序）")
    @GetMapping("/entries")
    public Result<Page<Diary>> listEntries(
            @AuthenticationPrincipal Long userId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(diaryService.listEntries(userId, page, size));
    }

    @Operation(summary = "查询单篇日记（含完整 Quill Delta content）")
    @GetMapping("/entries/{diaryId}")
    public Result<Diary> getEntry(@AuthenticationPrincipal Long userId,
                                  @PathVariable Long diaryId) {
        return Result.success(diaryService.getEntry(userId, diaryId));
    }

    @Operation(summary = "新增日记")
    @PostMapping("/entries")
    public Result<Diary> createEntry(@AuthenticationPrincipal Long userId,
                                     @RequestBody Diary req) {
        return Result.success(diaryService.createEntry(userId, req));
    }

    @Operation(summary = "更新日记（验证 userId 归属；仅传需修改字段）")
    @PutMapping("/entries/{diaryId}")
    public Result<Diary> updateEntry(@AuthenticationPrincipal Long userId,
                                     @PathVariable Long diaryId,
                                     @RequestBody Diary req) {
        return Result.success(diaryService.updateEntry(userId, diaryId, req));
    }

    @Operation(summary = "删除日记（验证 userId 归属）")
    @DeleteMapping("/entries/{diaryId}")
    public Result<Void> deleteEntry(@AuthenticationPrincipal Long userId,
                                    @PathVariable Long diaryId) {
        diaryService.deleteEntry(userId, diaryId);
        return Result.success();
    }

    // ──────── 5.3 月度日历视图 ────────

    @Operation(summary = "月度日记日历（返回本月有日记的日期映射 { \"2026-03-07\": true }）",
               description = "month 格式：yyyy-MM；默认当前月")
    @GetMapping("/entries/calendar")
    public Result<Map<String, Boolean>> getCalendar(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String month) {
        String ym = month != null ? month
                : YearMonth.now().format(DateTimeFormatter.ofPattern("yyyy-MM"));
        return Result.success(diaryService.getCalendar(userId, ym));
    }

    // ──────── 5.4 多条件搜索 ────────

    @Operation(summary = "按关键词/标签/分类/心情分页搜索日记",
               description = "所有参数可选，AND 组合过滤。keyword 匹配标题+正文；tag 模糊匹配 tags 字段。")
    @GetMapping("/entries/search")
    public Result<Page<Diary>> search(
            @AuthenticationPrincipal Long userId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String mood,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(diaryService.search(userId, keyword, tag, category, mood, page, size));
    }

    // ──────── 5.5 日记图片上传 ────────

    @Operation(summary = "上传日记图片，返回 URL（可直接插入 Quill Delta insert 节点）")
    @PostMapping("/photos")
    public Result<Map<String, String>> uploadPhoto(
            @AuthenticationPrincipal Long userId,
            @RequestParam("file") MultipartFile file) throws IOException {
        String url = diaryService.uploadPhoto(userId, file);
        return Result.success(Map.of("url", url));
    }
}
