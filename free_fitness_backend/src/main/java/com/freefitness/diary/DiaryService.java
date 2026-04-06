package com.freefitness.diary;

import com.freefitness.common.service.FileStorageService;
import com.freefitness.diary.entity.Diary;
import com.freefitness.diary.repository.DiaryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 日记模块服务：CRUD / 日历视图 / 多条件搜索 / 图片上传
 */
@Service
@RequiredArgsConstructor
public class DiaryService {

    private final DiaryRepository diaryRepo;
    private final FileStorageService storageService;

    @Value("${storage.diary-dir}")
    private String diaryDir;

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    private static final DateTimeFormatter D  = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    // ──────── 5.2 日记 CRUD ────────
    public List<Diary> listEntriesRange(Long userId, String startDate, String endDate, String dateSort) {
        if ("asc".equalsIgnoreCase(dateSort)) {
            return diaryRepo.findByUserIdAndDateBetweenOrderByDateAsc(userId, startDate, endDate);
        } else {
            return diaryRepo.findByUserIdAndDateBetweenOrderByDateDesc(userId, startDate, endDate);
        }
    }

    /** 分页查询日记列表（按日期倒序） */
    public Page<Diary> listEntries(Long userId, int page, int size) {
        return diaryRepo.findByUserIdOrderByDateDesc(userId, PageRequest.of(page, size));
    }

    /** 查询单篇日记 */
    public Diary getEntry(Long userId, Long diaryId) {
        Diary diary = diaryRepo.findById(diaryId)
                .orElseThrow(() -> new IllegalArgumentException("日记不存在：" + diaryId));
        assertOwner(diary, userId);
        return diary;
    }

    /** 新增日记 */
    @Transactional
    public Diary createEntry(Long userId, Diary req) {
        req.setDiaryId(null);
        req.setUserId(userId);
        if (req.getDate() == null) req.setDate(LocalDate.now().format(D));
        req.setGmtCreate(LocalDateTime.now().format(DT));
        return diaryRepo.save(req);
    }

    /** 更新日记（验证归属） */
    @Transactional
    public Diary updateEntry(Long userId, Long diaryId, Diary req) {
        Diary existing = diaryRepo.findById(diaryId)
                .orElseThrow(() -> new IllegalArgumentException("日记不存在：" + diaryId));
        assertOwner(existing, userId);

        // 仅更新非空字段
        if (req.getTitle()    != null) existing.setTitle(req.getTitle());
        if (req.getContent()  != null) existing.setContent(req.getContent());
        if (req.getTags()     != null) existing.setTags(req.getTags());
        if (req.getCategory() != null) existing.setCategory(req.getCategory());
        if (req.getMood()     != null) existing.setMood(req.getMood());
        if (req.getPhotos()   != null) existing.setPhotos(req.getPhotos());
        if (req.getDate()     != null) existing.setDate(req.getDate());
        existing.setGmtModified(LocalDateTime.now().format(DT));
        return diaryRepo.save(existing);
    }

    /** 删除日记（验证归属） */
    @Transactional
    public void deleteEntry(Long userId, Long diaryId) {
        Diary existing = diaryRepo.findById(diaryId)
                .orElseThrow(() -> new IllegalArgumentException("日记不存在：" + diaryId));
        assertOwner(existing, userId);
        diaryRepo.deleteById(diaryId);
    }

    // ──────── 5.3 日历视图 ────────

    /**
     * 返回某年月内有日记的日期映射
     */
    public Map<String, Boolean> getCalendar(Long userId, String yearMonth) {
        YearMonth ym = YearMonth.parse(yearMonth);
        String startDate = ym.atDay(1).format(D);
        String endDate   = ym.atEndOfMonth().format(D);

        List<String> dates = diaryRepo.findDatesByUserIdAndDateBetween(userId, startDate, endDate);
        return dates.stream().collect(Collectors.toMap(
                date -> date,
                date -> Boolean.TRUE,
                (a, b) -> a,
                LinkedHashMap::new
        ));
    }

    // ──────── 5.4 多条件搜索 ────────

    public Page<Diary> search(Long userId, String keyword, String tag,
                               String category, String mood, int page, int size) {
        return diaryRepo.search(userId, keyword, tag, category, mood, PageRequest.of(page, size));
    }

    // ──────── 5.5 日记图片上传 ────────

    /**
     * 上传日记图片，返回可供 Quill Delta insert 引用的 URL
     */
    public String uploadPhoto(Long userId, MultipartFile file) throws IOException {
        return storageService.storeFile(file, diaryDir, "/uploads/diary/");
    }

    // ──────── 工具 ────────

    private void assertOwner(Diary diary, Long userId) {
        if (!diary.getUserId().equals(userId)) {
            throw new IllegalArgumentException("无权访问或修改他人日记");
        }
    }
}
