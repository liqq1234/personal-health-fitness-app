package com.freefitness.health.controller;

import com.freefitness.health.entity.SleepRecord;
import com.freefitness.health.repository.SleepRecordRepository;
import com.freefitness.common.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@RestController
@RequestMapping("/api/v1/health/sleep")
public class SleepController {

    @Autowired
    private SleepRecordRepository sleepRepository;

    @PostMapping
    public Result<SleepRecord> addSleep(@RequestBody SleepRecord record) {
        record.setGmtCreate(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        SleepRecord saved = sleepRepository.save(record);
        return Result.success(saved);
    }

    @GetMapping("/{userId}")
    public Result<List<SleepRecord>> getSleepRecords(@PathVariable Long userId) {
        List<SleepRecord> list = sleepRepository.findByUserIdOrderByStartTimeDesc(userId);
        return Result.success(list);
    }
}
