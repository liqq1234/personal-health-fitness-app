package com.freefitness.diary.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 日记（对应 ff_diary 表）
 * content 字段存储 Quill Delta JSON 格式的富文本
 * photos 字段存储图片 URL JSON 数组（图片由 /diary/photos 接口上传后引用）
 */
@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_diary")
public class Diary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "diary_id")
    private Long diaryId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "`date`", nullable = false, length = 12)
    private String date;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "content", nullable = false, columnDefinition = "MEDIUMTEXT")
    private String content;   // Quill Delta JSON

    @Column(name = "tags", columnDefinition = "TEXT")
    private String tags;

    @Column(name = "category", length = 64)
    private String category;

    @Column(name = "mood", length = 32)
    private String mood;

    @Column(name = "photos", columnDefinition = "TEXT")
    private String photos;   // JSON 数组格式 URL 列表

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    @Column(name = "gmt_modified", length = 30)
    private String gmtModified;
}
