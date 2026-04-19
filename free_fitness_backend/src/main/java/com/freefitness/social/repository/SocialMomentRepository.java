package com.freefitness.social.repository;

import com.freefitness.social.entity.SocialMoment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SocialMomentRepository extends JpaRepository<SocialMoment, Long> {
    List<SocialMoment> findByUserIdOrderByGmtCreateDesc(Long userId);
    List<SocialMoment> findByUserIdInOrderByGmtCreateDesc(List<Long> userIds);
}
