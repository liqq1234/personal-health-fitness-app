package com.freefitness.social.repository;

import com.freefitness.social.entity.SocialLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SocialLikeRepository extends JpaRepository<SocialLike, Long> {
    List<SocialLike> findByMomentIdOrderByGmtCreateAsc(Long momentId);
    Optional<SocialLike> findByUserIdAndMomentId(Long userId, Long momentId);
    long countByMomentId(Long momentId);
}
