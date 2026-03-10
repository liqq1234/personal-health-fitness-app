package com.freefitness.diary.repository;

import com.freefitness.diary.entity.Diary;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface DiaryRepository extends JpaRepository<Diary, Long> {

    /** 日记列表（按时间倒序分页） */
    Page<Diary> findByUserIdOrderByDateDesc(Long userId, Pageable pageable);

    /** 日历视图：查询某月内有日记的所有日期（yyyy-MM-dd） */
    @Query("SELECT d.date FROM Diary d WHERE d.userId = :userId " +
           "AND d.date BETWEEN :startDate AND :endDate")
    List<String> findDatesByUserIdAndDateBetween(@Param("userId")    Long userId,
                                                 @Param("startDate") String startDate,
                                                 @Param("endDate")   String endDate);

    /** 多条件搜索：关键词（标题/内容）、标签、分类、心情 */
    @Query("SELECT d FROM Diary d WHERE d.userId = :userId " +
           "AND (:keyword  IS NULL OR d.title   LIKE %:keyword%  OR d.content LIKE %:keyword%) " +
           "AND (:tag      IS NULL OR d.tags    LIKE %:tag%) " +
           "AND (:category IS NULL OR d.category = :category) " +
           "AND (:mood     IS NULL OR d.mood     = :mood) " +
           "ORDER BY d.date DESC")
    Page<Diary> search(@Param("userId")   Long userId,
                       @Param("keyword")  String keyword,
                       @Param("tag")      String tag,
                       @Param("category") String category,
                       @Param("mood")     String mood,
                       Pageable pageable);
}
