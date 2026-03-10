package com.freefitness.training.repository;

import com.freefitness.training.entity.Action;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ActionRepository extends JpaRepository<Action, Long> {
    List<Action> findByGroupId(Long groupId);
    void deleteByGroupId(Long groupId);
}
