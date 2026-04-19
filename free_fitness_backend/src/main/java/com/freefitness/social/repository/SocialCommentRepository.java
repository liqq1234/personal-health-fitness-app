package com.freefitness.social.repository;

import com.freefitness.social.entity.SocialComment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SocialCommentRepository extends JpaRepository<SocialComment, Long> {
    List<SocialComment> findByMomentIdOrderByGmtCreateAsc(Long momentId);
}
